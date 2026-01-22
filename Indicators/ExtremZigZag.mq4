//+------------------------------------------------------------------+
//|                                                 ExtremZigZag.mq4 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property strict
#property indicator_chart_window

#property   indicator_buffers 7
    
//---- Define Search States
#define _SEARCH_PEAK_   +1
#define _SEARCH_BOTH_   0
#define _SEARCH_VALLEY_ -1

//---- Define ZigZag Parameters
extern int
   Type        = 1,         // 0-old, 1-new
   Depth       = 5,         // Depth Search of ZigZag Extreems
   BackStep    = 3;         // BackStep for ZigZag Extreems
extern double
   Deviation   = 2.0,       // Price Deviation of ZigZag Extreems
   Distance    = 400,
   Step        = 200;

//---- Define ZigZagZug Buffers
double
   dblArrayZigZag[],                // ZigZag Points
   dblArrayZigZagHigh[],            // ZigZag Highs
   dblArrayZigZagLow[],             // ZigZag Lows
   dblArrayHigh[],                  // Running High of Depth Search
   dblArrayLow[],                   // Running Low of Depth Search
   extremLow[],
   extremHigh[];

//---- Define Extra Variables
bool
   boolDownloadHistory = false;     // Download History Data
int
   intLevel            = 3,         // For Depth Recounting
   intIndexLimit       = 100;       // Limit Count of Index
        
int init()
{
   // Set Number of Buffers to be used
   IndicatorBuffers(7);
   
   // Set Number of Digits (Precision)
   IndicatorDigits(Digits);  
   
   // Set Buffer Index
   SetIndexBuffer(0, dblArrayZigZag);
   SetIndexBuffer(1, dblArrayZigZagHigh);
   SetIndexBuffer(2, dblArrayZigZagLow);
   SetIndexBuffer(3, dblArrayHigh);
   SetIndexBuffer(4, dblArrayLow);
   SetIndexBuffer(5, extremLow);
   SetIndexBuffer(6, extremHigh);
   
   // Set Index Label
   SetIndexLabel(0, NULL);
   SetIndexLabel(1, NULL);
   SetIndexLabel(2, NULL);
   SetIndexLabel(3, NULL);
   SetIndexLabel(4, NULL);
   SetIndexLabel(5, NULL);
   SetIndexLabel(6, NULL);
   
   // Set Line Style
   SetIndexStyle(0, DRAW_NONE);
   SetIndexStyle(1, DRAW_NONE);
   SetIndexStyle(2, DRAW_NONE);
   SetIndexStyle(3, DRAW_NONE);
   SetIndexStyle(4, DRAW_NONE);
   SetIndexStyle(5, DRAW_NONE);
   SetIndexStyle(6, DRAW_NONE);
   
   // Set Arrow Types
   SetIndexArrow(1, 108);
   SetIndexArrow(2, 108);
   
   // Set Empty Value
   SetIndexEmptyValue(0, NULL);
   SetIndexEmptyValue(1, NULL);
   SetIndexEmptyValue(2, NULL);
   SetIndexEmptyValue(3, NULL);
   SetIndexEmptyValue(4, NULL);
   SetIndexEmptyValue(5, NULL);
   SetIndexEmptyValue(6, NULL);
   
   Step *= Point;
   Distance *= Point;
   
   if(Digits == 4 || (Digits == 2 && StringFind(Symbol(), "JPY") != -1)) Deviation *= 1;
   else if(Digits == 5 || (Digits == 3 && StringFind(Symbol(), "JPY") != -1) || (Digits == 2 && StringFind(Symbol(), "XAU") != -1) || (Digits == 3 && StringFind(Symbol(), "XAG") != -1)) Deviation *= 10;
   else if(Digits == 6 || (Digits == 4 && StringFind(Symbol(), "JPY") != -1) || (Digits == 3 && StringFind(Symbol(), "XAU") != -1) || (Digits == 4 && StringFind(Symbol(), "XAG") != -1)) Deviation *= 100;
   
   // Correct External Variables
   if(Depth    < 1) Depth    = 1;
   if(BackStep < 1) BackStep = 1;
   
   Deviation = MathRound(MathAbs(Deviation)) * Point;
   
   return(NULL);
}
        
//---- Initialise Buffer Index and other Properties
int start()
{
  int
      intLimitBars,   intCountedBars  = IndicatorCounted()
  ,   intCounter,     intSearch       = _SEARCH_BOTH_
  ,   intLowPosition, intHighPosition
  ,   intShift,       intBack
  ,   intIndex
  ;
  double
      dblResult,      dblValue
  ,   dblCurrentLow,  dblCurrentHigh
  ,   dblPreviousLow, dblPreviousHigh
  ;
  
  if ( intCountedBars < 0 )
      return( EMPTY );
  
  intLimitBars = 0;
  if( intCountedBars == 0 )
  {
      // Check for Downloaded History Data
      if( boolDownloadHistory )
      {
          ArrayInitialize( dblArrayZigZag, NULL );
          ArrayInitialize( dblArrayZigZagHigh, NULL );
          ArrayInitialize( dblArrayZigZagLow, NULL );
          ArrayInitialize( dblArrayHigh, NULL );
          ArrayInitialize( dblArrayLow, NULL );
          ArrayInitialize( extremLow, NULL );
          ArrayInitialize( extremHigh, NULL );
      }

      intLimitBars = Bars - Depth;
      boolDownloadHistory = true;
  }
      
  if ( intCountedBars > 0 )
  {
      for(    intIndex = 0, intCounter = 0;
              ( intCounter < intLevel ) && ( intIndex < intIndexLimit );
              intIndex++ )
      {
          dblResult = dblArrayZigZag[ intIndex ];
          if( dblResult != 0 ) intCounter++;
      }
  
      intIndex--;
  
      intLimitBars = intIndex;
  
      dblResult = dblArrayZigZagLow[ intIndex ];
      if( dblResult != 0 ) 
      {
          dblCurrentLow = dblResult;
          intSearch = _SEARCH_PEAK_;
      }
      else
      {
          dblCurrentHigh = dblArrayZigZagHigh[ intIndex ];
          intSearch = _SEARCH_VALLEY_;
      }
  
      for( intIndex = intLimitBars - 1; intIndex >= 0; intIndex-- )
      {
          dblArrayZigZag[ intIndex ]          = NULL;
          dblArrayZigZagLow[ intIndex ]       = NULL;
          dblArrayZigZagHigh[ intIndex ]      = NULL;
      }   
  }  
  
  //---- Initial Analysis of Data
  
  for( intShift = intLimitBars; intShift >= 0; intShift-- )
  {
      //---- Verify the High Value
      dblArrayHigh[ intShift ] = High[ iHighest( NULL, 0, MODE_HIGH, Depth, intShift ) ];
      dblValue = dblArrayHigh[ intShift ];
      
      if( dblValue == dblPreviousHigh )
          dblValue = NULL;
      else
      {
          dblPreviousHigh = dblValue;
          
          if( ( dblValue - High[ intShift ] ) > Deviation )
              dblValue = NULL;
          else
          {
              for( intBack = 1; intBack <= BackStep; intBack++ )
              {
                  dblResult = dblArrayZigZagHigh[ intShift + intBack ];
                  if( ( dblResult != 0 ) && ( dblResult < dblValue ) )
                      dblArrayZigZagHigh[ intShift + intBack ] = NULL; 
              }
          }
      }
      
      if( High[ intShift ] == dblValue)
          dblArrayZigZagHigh[ intShift ] = dblValue;
      else
          dblArrayZigZagHigh[ intShift ] = NULL;

          
      //---- Verify the Low Value
      dblArrayLow[ intShift ] = Low[ iLowest( NULL, 0, MODE_LOW, Depth, intShift ) ];
      dblValue = dblArrayLow[ intShift ];
      
      if( dblValue == dblPreviousLow )
          dblValue = NULL;
      else
      {
          dblPreviousLow = dblValue;
          
          if( ( Low[ intShift ] - dblValue ) > Deviation )
              dblValue = NULL;
          else
          {
              for( intBack = 1; intBack <= BackStep; intBack++ )
              {
                  dblResult = dblArrayZigZagLow[ intShift + intBack ];
                  if( ( dblResult != 0 ) && ( dblResult > dblValue ) )
                      dblArrayZigZagLow[ intShift + intBack ] = NULL; 
              } 
          }
      }
      
      if( Low[ intShift ] == dblValue)
          dblArrayZigZagLow[ intShift ] = dblValue;
      else
          dblArrayZigZagLow[ intShift ] = NULL;
  }
    
  //---- Final Filtering and Adjustments
  
  if( intSearch == _SEARCH_BOTH_ )
  {
      dblPreviousLow  = NULL;
      dblPreviousHigh = NULL;
  }
  else
  {
      dblPreviousLow  = dblCurrentLow;
      dblPreviousHigh = dblCurrentHigh;
  }
  
  for( intShift = intLimitBars; intShift >= 0; intShift-- )
  {
      switch( intSearch )
      {
          case _SEARCH_BOTH_:
              if( ( dblPreviousLow == NULL ) && ( dblPreviousHigh == NULL ) )
              {
                  if( dblArrayZigZagHigh[ intShift ] != NULL )
                  {
                      intHighPosition             = intShift;
                      dblPreviousHigh             = High[ intShift ];
                      dblArrayZigZag[ intShift ]  = dblPreviousHigh;
                      intSearch                   = _SEARCH_VALLEY_;
                  }
                  
                  if( dblArrayZigZagLow[ intShift ] != NULL )
                  {
                      intLowPosition              = intShift;
                      dblPreviousLow              = Low[ intShift ];
                      dblArrayZigZag[ intShift ]  = dblPreviousLow;
                      intSearch                   = _SEARCH_PEAK_;
                  }
              }
              break;
      

          case _SEARCH_PEAK_:
              if( dblArrayZigZagHigh[ intShift ] == NULL )
              {
                  if( ( dblArrayZigZagLow[ intShift ] != NULL             ) &&
                      ( dblArrayZigZagLow[ intShift ] < dblPreviousLow    )       )
                  {
                      dblArrayZigZag[ intLowPosition ]    = NULL;
                      intLowPosition                      = intShift;
                      dblPreviousLow                      = dblArrayZigZagLow[ intShift ];
                      dblArrayZigZag[ intShift ]          = dblPreviousLow;
                  }
              }
              else
              {
                  if( dblArrayZigZagLow[ intShift ] == NULL )
                  {
                      intHighPosition                     = intShift;
                      dblPreviousHigh                     = dblArrayZigZagHigh[ intShift ];
                      dblArrayZigZag[ intShift ]          = dblPreviousHigh;
                      intSearch                           = _SEARCH_VALLEY_;
                  }
              }
              break;

          case _SEARCH_VALLEY_:
              if( dblArrayZigZagLow[ intShift ] == NULL )
              {
                  if( ( dblArrayZigZagHigh[ intShift ]    != NULL             ) &&
                      ( dblArrayZigZagHigh[ intShift ]    > dblPreviousHigh   )       )
                  {
                      dblArrayZigZag[ intHighPosition ]   = NULL;
                      intHighPosition                     = intShift;
                      dblPreviousHigh                     = dblArrayZigZagHigh[ intShift ];
                      dblArrayZigZag[ intShift ]          = dblPreviousHigh;
                  }
              }
              else
              {
                  if( dblArrayZigZagHigh[ intShift ] == NULL )
                  {
                      intLowPosition                      = intShift;
                      dblPreviousLow                      = dblArrayZigZagLow[ intShift ];
                      dblArrayZigZag[ intShift ]          = dblPreviousLow;
                      intSearch                           = _SEARCH_PEAK_;
                  }
              }
              break;
      }
  }
  
   int size;
   double zigzag[];
   int count = ArraySize(dblArrayZigZag);
   for(int i = 0; i < count; i++)
   {
      if(dblArrayZigZag[i] < Point) continue;
      
      size = ArraySize(zigzag);
      ArrayResize(zigzag, size+1, count);
      zigzag[size] = dblArrayZigZag[i];
   }  

   double max = NULL;
   double min = EMPTY_VALUE;
   double buy = NULL;
   double sell = NULL;
   size = ArraySize(zigzag);
   int ind = 0;
   if(size > ind)
   {
      min = zigzag[ind];
      max = zigzag[ind];
      buy = NULL;
      sell = EMPTY_VALUE;
   }
   
   if(Type==0)calculateByType0(size, ind, zigzag, min, max, buy, sell);
   else calculateByType1(size, ind, zigzag, min, max, buy, sell);
      
   extremLow[0] = sell;
   extremHigh[0] = buy;

/*Print("SELL: ",DoubleToStr(extremLow[0],Digits)," | BUY: ",DoubleToStr(extremHigh[0],Digits));
ObjectCreate("Buy",OBJ_HLINE,0,0,extremHigh[0]);
ObjectSet("Buy",OBJPROP_PRICE1,extremHigh[0]);
ObjectCreate("Sell",OBJ_HLINE,0,0,extremLow[0]);
ObjectSet("Sell",OBJPROP_PRICE1,extremLow[0]);
ChartRedraw(ChartID());*/
   return( NULL );
}

void calculateByType0(const int _size, const int _start, const double &zigzag[], double &min, double &max, double &buy, double &sell)
{   
   double dif = 0.0;
   for(int i = _start+1; i < _size; i++)
   {
      min = MathMin(min, zigzag[i]);
      max = MathMax(max, zigzag[i]);
      dif = zigzag[i]-zigzag[i-1];
      
      if(Step - MathAbs(dif) > 0.0)
      {
         if(dif > 0.0) sell = min;
         else buy = max;
      }
      else
      {
         if(dif > 0.0)
         {
            if(zigzag[i-1] < sell) sell = zigzag[i-1];
         }
         else
         {
            if(zigzag[i-1] > buy) buy = zigzag[i-1];
         }
      }
      
      if(MathAbs(max - min) > Distance)
      {
         if(dif > 0.0)
         {
            if(min < sell) sell = min;
         }
         else
         {
            if(max > buy) buy = max;
         }
         if(buy == NULL) buy = max;
         if(sell == EMPTY_VALUE) sell = min;
         break;
      }
   }
}

void calculateByType1(const int _size, const int _start, const double &zigzag[], double &min, double &max, double &buy, double &sell)
{   
   double dif = 0.0;
   bool isBuy = false;
   bool isSell = false;
   for(int i = _start+1; i < _size; i++)
   {
      min = MathMin(min, zigzag[i]);
      max = MathMax(max, zigzag[i]);
      dif = zigzag[i]-zigzag[i-1];
      
      if(Step - MathAbs(dif) > 0.0)
      {
         if(dif < 0.0 && !isBuy) buy = max;
         if(dif > 0.0 && !isSell) sell = min;
      }
      else
      {
         if(dif < 0.0 && !isBuy)
         {
            isBuy = true;
            buy = MathMax(buy, zigzag[i-1]);
         }
         if(dif > 0.0 && !isSell)
         {
            isSell = true;
            sell = MathMin(sell, zigzag[i-1]);
         }
      }
      
      if(isBuy && isSell) break;
   }
}
