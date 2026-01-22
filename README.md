# Extreme (MetaTrader 4)

Ez a repository MetaTrader 4 (MT4) környezethez készült MQL4 kódot tartalmaz: két Expert Advisor-t (EA) és két indikátort, amelyek az „Extrem” stratégiák alapját adják.

A projekt fő elemei:
- **Experts**: kereskedési robotok (EA-k)
  - `ExtremLimit.mq4` – *Extrem LIMIT Strategy*
  - `ExtremStop.mq4` – *Extrem STOP Strategy*
- **Indicators**: indikátorok
  - `ExtremZigZag.mq4` – ZigZag alapú szélsőérték (extremum) számítás és jel előállítás
  - `ExtremSuperTrend.mq4` – SuperTrend (ATR alapú) trendkövető jelölés
- **Libraries**: natív DLL-ek
  - `Extrem.dll`, `Extrem.x64.dll` – az EA-k által importált segédfüggvények (szinkronizáció / állapotkezelés)

A repóban található két `.mkv` fájl (`ExtremLimitStrategy.mkv`, `ExtremStopStrategy.mkv`) a stratégiák működését bemutató videók.

## Követelmények

- **MetaTrader 4** terminál
- MQL4 fordító (MT4 MetaEditor)
- A stratégiák a következő erőforrásokra hivatkoznak:
  - `\Indicators\ExtremZigZag.ex4`
  - `\Indicators\ExtremSuperTrend.ex4`
- A futáshoz szükséges DLL-k:
  - `Libraries/Extrem.dll` (32-bit)
  - `Libraries/Extrem.x64.dll` (64-bit)

> Megjegyzés: MT4-ben a DLL használat engedélyezése szükséges (Expert Advisor beállításokban: **Allow DLL imports**).

## Telepítés / fájlok helye MT4-ben

A repository felépítése megfeleltethető az MT4 `MQL4` könyvtárának:

- `Experts/ExtremLimit.mq4` → `<MT4>/MQL4/Experts/ExtremLimit.mq4`
- `Experts/ExtremStop.mq4` → `<MT4>/MQL4/Experts/ExtremStop.mq4`
- `Indicators/ExtremZigZag.mq4` → `<MT4>/MQL4/Indicators/ExtremZigZag.mq4`
- `Indicators/ExtremSuperTrend.mq4` → `<MT4>/MQL4/Indicators/ExtremSuperTrend.mq4`
- `Libraries/Extrem.dll` → `<MT4>/MQL4/Libraries/Extrem.dll`
- `Libraries/Extrem.x64.dll` → `<MT4>/MQL4/Libraries/Extrem.x64.dll`

Ezután MetaEditorban fordítsd le az indikátorokat és az EA-kat (vagy másold be az előre lefordított `.ex4` fájlokat az `Indicators` mappába).

## Indikátorok részletesen (működési elv)

### ExtremSuperTrend – trendfázis ATR alapján

Az `Indicators/ExtremSuperTrend.mq4` egy klasszikus, ATR-alapú SuperTrend jellegű indikátor.

**Fő paraméterek**
- `ATR_Period` (alapértelmezés: 10)
- `ATR_Multiplier` (alapértelmezés: 3.0)

**Számítási lényeg**
- ATR-t számol (`iATR`), ebből egy távolságot képez: `distance = ATR_Multiplier * ATR`.
- Medián árat vesz: `(High + Low) / 2`.
- Ebből két sávot képez:
  - `band_upper = medianPrice + distance`
  - `band_lower = medianPrice - distance`
- Egy `phase` állapotváltozóval (PHASE_NONE/PHASE_BUY/PHASE_SELL) kezeli a trendfázist.

**Trendváltási feltételek (kódszintű logika)**
- BUY fázisba vált, ha a záróár a korábbi down vonal fölé kerül:
  - `Close[i] > buffer_line_down[i+1]`
- SELL fázisba vált, ha a záróár a korábbi up vonal alá kerül:
  - `Close[i] < buffer_line_up[i+1]`

**Mit ad az EA-nak?**
- Egy irányszűrőt (BUY/SELL fázis), illetve potenciális „defenzív” kilépési/trendforduló jelzést.

### ExtremZigZag – extremum szintek (buy/sell level) előállítása

Az `Indicators/ExtremZigZag.mq4` két részből áll:
1. klasszikus ZigZag pontok (csúcs/völgy) keresése (`Depth`, `BackStep`, `Deviation`),
2. ezekből **két kulcsszint** számítása a legfrissebb adatok alapján:
   - `extremHigh[0]` → *buy level*
   - `extremLow[0]` → *sell level*

**Fő paraméterek**
- ZigZag: `Depth`, `BackStep`, `Deviation`
- Szintképzés: `Step`, `Distance`
- `Type` (0: régi, 1: új számítási logika; alapértelmezés: 1)

**Szintképzés lényege**
- A ZigZag pontokból a kód egy tömörített `zigzag[]` listát készít.
- Ezután a `Type` szerint meghívja:
  - `calculateByType0(...)` vagy
  - `calculateByType1(...)`
- A függvények a ZigZag pontok közti különbségből (`dif = zigzag[i] - zigzag[i-1]`) és a küszöbökből (`Step`, `Distance`) állítják elő a két szintet.

**Type=1 (új) rövid értelmezés**
- „Kisebb” mozgásoknál (`abs(dif) < Step`) jelölt szinteket képez:
  - negatív dif esetén buy jelöltet,
  - pozitív dif esetén sell jelöltet.
- „Nagyobb” mozgásoknál a fordulóponttal megerősíti a szinteket, és ha már mindkét oldal megvan, leáll.

**Mit ad az EA-nak?**
- Két ár-szintet (buy/sell), amelyekhez a robot pending megbízásokat igazíthat.

## Expert Advisor-ok (EA-k) – működési elv

> Fontos: a `Experts/ExtremLimit.mq4` és `Experts/ExtremStop.mq4` a repository-ban UTF-16 formátumban található. Ez fordításra jó lehet, de GitHub-on és egyszerű szövegfeldolgozóval nehezebben elemezhető. A működési elv alábbi leírása a kódban látható paraméterezésből, DLL interfészekből és az indikátorok működéséből következik.

### Közös alapok

Mindkét EA:
- erőforrásként használja az `ExtremZigZag` és `ExtremSuperTrend` indikátorokat (EX4 formában),
- importálja az `Extrem.dll`-t,
- tartalmaz naplózót (fájlos log), chart kommenteket és értesítéseket.

### Állapotvédelem / szinkronizáció (DLL)

A két EA importálja az alábbi függvényeket:
- `isProcessingDLL()` / `setProcessingDLL(bool)`
- `isEqualDLL(MqlDateTime&)`
- `setLastOpenedBarDLL(MqlDateTime&)

**Tipikus szerepük**
- védik a kereskedési logikát a többszörös tick feldolgozástól (ugyanazon bar/tick többszöri végrehajtása),
- kritikus szakasz jellegű „processing” flag-et adnak (ne fusson párhuzamosan order nyitás/módosítás).

### Belépési koncepció (szintek + trendfázis)

A rendszer alap gondolata:
1. Az `ExtremZigZag` ad két szintet:
   - `extremHigh` (buy level)
   - `extremLow` (sell level)
2. Az `ExtremSuperTrend` ad egy trend-állapotot (BUY/SELL fázis).
3. Az EA a konfigurációtól függően pending megbízásokat helyez el a szintek környezetébe:
   - **ExtremStop**: tipikusan kitörés jelleg (STOP pending-ek a szintek felé/irányába)
   - **ExtremLimit**: tipikusan visszahúzódás jelleg (LIMIT pending-ek a szintekhez visszatérésre)

### Pozíció- és kockázatkezelés

A paraméterek alapján a robot képes:
- több lépcsőben pozíciót építeni (`MaxTrades`),
- lotot skálázni (`Multiplier`) – ez grid/martingale jellegű elemet jelezhet,
- a lot indulását automatikusan vagy fixen kezelni (`AutoStartLot`, `StartLot`),
- kockázati profilt választani (`Risk`: Conservative/Normal/Aggressive).

### Kilépési koncepció (ExitStrategy)

A kódban definiált kilépési módok:
- `SUPER_TREND`: trendforduló / SuperTrend alapú zárás
- `PEAK_VALLEY`: ZigZag szélsőérték (peak/valley) alapú zárás
- `MANUAL`: kézi zárás (EA inkább menedzsel/figyel)

További kapcsolódó opciók:
- `Defensive`: defenzív kilépés (pl. trendforduló vagy kockázati esemény esetén agresszívebb zárás)
- `TargetProfit`: kosár/cél profit elérésekor zárás
- `ExitObserver`, `ObserverStart`, `ObserverEnd`: időablak alapú kilépési felügyelet

## Naplózás és megjelenítés

- **Logger**: fájl alapú napló (szintek: DEBUG/INFO/WARNING/ERROR)
- **Chart komment**: futás közbeni állapot összegzés
- **Értesítések**: MT4 push notification (`Notifications`)

## Biztonsági / használati megjegyzések

- A paraméterek (különösen `Multiplier`, `MaxTrades`) alapján a stratégia tartalmazhat **pozíció-építést / skálázást**, ami **magas kockázatú**.
- Valós számlán használat előtt javasolt:
  - backtest,
  - demo teszt,
  - konzervatív profil (alacsony lot, alacsony MaxTrades, óvatos Multiplier).

## Licenc

A licenc a `LICENSE` fájlban található.