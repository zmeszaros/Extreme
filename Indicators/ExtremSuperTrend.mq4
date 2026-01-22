//+------------------------------------------------------------------+
//|                                             ExtremSuperTrend.mq4 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.01"
#property strict

#property indicator_chart_window
#property indicator_buffers 2
#property indicator_color1 Lime
#property indicator_color2 Red
#property indicator_width1 2
#property indicator_width2 2
 
#define PHASE_NONE 0
#define PHASE_BUY 1
#define PHASE_SELL -1
 
extern int    ATR_Period      = 10;
extern double ATR_Multiplier  = 3.0;
 
int phase;
double buffer_line_up[], buffer_line_down[];
double atr, band_upper, band_lower;

int OnInit()
{
   phase = PHASE_NONE;
   IndicatorDigits((int)MarketInfo(Symbol(), MODE_DIGITS));
   
   SetIndexBuffer(0, buffer_line_up);
   SetIndexLabel(0, "Up Trend");
   SetIndexStyle(0, DRAW_ARROW, 159, 1);
   SetIndexBuffer(1, buffer_line_down);
   SetIndexLabel(1, "Down Trend");
   SetIndexStyle(1, DRAW_ARROW, 159, 1);
   
   return(INIT_SUCCEEDED);
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   double distance = 0.0;
   double medianPrice = 0.0;
   int bars_counted = IndicatorCounted();
   
   if(bars_counted < 0) return(1);
   else if(bars_counted > 0) bars_counted--;

   int limit = Bars - bars_counted - 2;
   
   for(int i = limit; i >= 1; i--)
   {
      atr = iATR(Symbol(), 0, ATR_Period, i);
      distance = ATR_Multiplier * atr;
      medianPrice = (High[i] + Low[i]) / 2;
      band_upper = medianPrice + distance;
      band_lower = medianPrice - distance;
            
      if(phase == PHASE_NONE)
      {
         buffer_line_up[i] = (High[i+1] + Low[i+1]) / 2;
         buffer_line_down[i] = (High[i+1] + Low[i+1]) / 2;
      }
      
      if(phase != PHASE_BUY && Close[i] > buffer_line_down[i+1] && buffer_line_down[i+1] != EMPTY_VALUE)
      {
         phase = PHASE_BUY;
         buffer_line_up[i] = band_lower;
         buffer_line_up[i+1] = buffer_line_down[i+1];
         
         //buffer_line_up[i+1] = NULL;
      }
      
      if(phase != PHASE_SELL && Close[i] < buffer_line_up[i+1] && buffer_line_up[i+1] != EMPTY_VALUE)
      {
         phase = PHASE_SELL;
         buffer_line_down[i] = band_upper;
         buffer_line_down[i+1] = buffer_line_up[i+1];
         
         buffer_line_down[i+1] = NULL;
      }
      
      if(ArraySize(buffer_line_up) > i+2)
         if(phase == PHASE_BUY && buffer_line_up[i+2] != EMPTY_VALUE)
         {
            if(band_lower > buffer_line_up[i+1]) buffer_line_up[i] = band_lower;
            else buffer_line_up[i] = buffer_line_up[i+1];
         }
      if(ArraySize(buffer_line_down) > i+2)
         if(phase == PHASE_SELL && buffer_line_down[i+2] != EMPTY_VALUE)
         {
            if(band_upper < buffer_line_down[i+1]) buffer_line_down[i] = band_upper;
            else buffer_line_down[i] = buffer_line_down[i+1];
         }      
   }

//Print("UP: ",DoubleToStr(buffer_line_up[1],Digits));
//Print("Down: ",DoubleToStr(buffer_line_down[1],Digits));
   return(rates_total);
}
