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

## Indikátorok röviden

### ExtremSuperTrend

Az `ExtremSuperTrend.mq4` egy ATR alapú SuperTrend indikátor.
- Paraméterek:
  - `ATR_Period` (alapértelmezetten 10)
  - `ATR_Multiplier` (alapértelmezetten 3.0)
- Két bufferrel jelöl trendet (fel/le), a chart ablakban rajzol.

### ExtremZigZag

Az `ExtremZigZag.mq4` a klasszikus ZigZag számítást végzi, majd a végén **szélsőérték szinteket** számol:
- a kimeneten `extremHigh[0]` (buy szint) és `extremLow[0]` (sell szint) jelenik meg,
- a számítás a ZigZag pontokból, `Step` és `Distance` paraméterekből képez jelölteket.

Fontosabb paraméterek:
- `Type` (0: régi, 1: új számítási logika)
- `Depth`, `BackStep`, `Deviation`
- `Distance`, `Step`

## Expert Advisor-ok (EA-k)

A két EA szerkezete nagy részben hasonló, a különbség a belépési / menedzsment logika részleteiben van:

- `ExtremLimit.mq4` – *Limit* jellegű (függő) megbízásokkal dolgozó stratégia.
- `ExtremStop.mq4` – *Stop* jellegű (függő) megbízásokkal dolgozó stratégia.

Mindkettő:
- erőforrásként használja az `ExtremZigZag` és `ExtremSuperTrend` indikátorokat (EX4 formában),
- importálja az `Extrem.dll`-t,
- tartalmaz naplózót (fájlos log), chart kommenteket és értesítéseket (MT4 push notification),
- több instrumentumhoz (pl. EURCHF, USDCHF, EURGBP) definiál alapértékeket / lépésközöket.

### Főbb beállítások (extern paraméterek)

Mindkét EA-ban megtalálhatóak (a lista nem teljes):
- `Portion` – százalékos arány (kockázat / lot számítás alapja)
- `Risk` – kockázati mód (Conservative / Normal / Aggressive)
- `MaxTrades` – maximális kötésszám
- `TargetProfit` – cél profit (0 esetén általában nincs fix TP cél)
- `Multiplier` – lot növelési szorzó (grid / martingale jellegű skálázás)
- `ManualStart` – kézi indítás
- `OpenLimitsAtOnce` (csak Limit EA-ban) – limit megbízások egyszerre nyitása
- `MassOrders`, `TrailingOrders` (Stop EA-ban) – pending-ek tömeges kezelése / trailing
- `Defensive` – defenzív kilépés
- `KeepAlive` – „életjel”/futás fenntartás jellegű logika
- `ManagedOn` – menedzsment idősíkja
- `AutoStartLot` / `StartLot` – induló lot automatikus vagy fix
- `ExtremeMovements` – extrém mozgás szűrő (ATR alapú)
- `ExitStrategy` – kilépési stratégia (SuperTrend / Peak-Valley / Manual)
- `ExitObserver` + `ObserverStart`/`ObserverEnd` – idősáv alapú felügyelet
- `MagicNumber` – egyedi EA azonosító
- `Notifications` – push értesítések
- `ControlPanel` – charton megjelenő vezérlőpanel

## Működési áttekintés (magas szint)

1. **Indikátorokból származó szintek/jelzések**
   - `ExtremZigZag` ad szélsőérték alapú buy/sell szinteket.
   - `ExtremSuperTrend` trendfázist jelez ATR alapján.
2. **Belépés**
   - Az EA a konfigurációtól függően függő megbízásokat (limit/stop) helyez el a számolt szintekhez.
3. **Pozíció- és kockázatkezelés**
   - Több kötés kezelése (`MaxTrades`), lot skálázás (`Multiplier`).
   - Spread / stop level / lot step stb. figyelembevétele (`SymbolProperty` jellegű logika).
4. **Kilépés**
   - `ExitStrategy` szerint: SuperTrend alapú, szélsőérték (peak-valley) alapú, vagy kézi.
5. **Állapotvédelem / szinkronizáció**
   - A DLL függvények (pl. `isProcessingDLL`, `setProcessingDLL`, `setLastOpenedBarDLL`) a versenyhelyzetek és többszörös tick feldolgozás csökkentését szolgálhatják.

## Naplózás és megjelenítés

- **Logger**: napló fájlba (`log_YYYY.MM.DD.log` jellegű név), különböző szintekkel (DEBUG/INFO/WARNING/ERROR).
- **Chart comment**: az EA a charton összegzi a fő állapotot (kötésszám, lot, profit, stb.).
- **Push értesítések**: MT4 `SendNotification` használatával.

## Biztonsági / használati megjegyzések

- A stratégia grid/multiplikátoros elemeket tartalmazhat, ami **magas kockázatú**.
- Valós számlán használat előtt javasolt:
  - backtest,
  - demo teszt,
  - kis kockázatú beállítás (Conservative, alacsony MaxTrades, alacsony StartLot).

## Licenc

A licenc a `LICENSE` fájlban található.