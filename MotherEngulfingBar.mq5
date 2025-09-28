//+------------------------------------------------------------------+
//|                                            MotherEngulfingBar.mq5 |
//|                        Copyright 2023, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window

// Structure to hold box information
struct BoxInfo {
    string name;
    datetime time1;
    double price1;
    datetime time2;
    double price2;
};

// Array to store box information
BoxInfo boxes[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| UpdateBoxes function - fixes ObjectSetTime compilation error    |
//+------------------------------------------------------------------+
void UpdateBoxes() {
    datetime new_end_time = TimeCurrent();
    
    for(int i = 0; i < ArraySize(boxes); i++) {
        // FIXED: Replace ObjectSetTime with ObjectMove
        // Original problematic code: ObjectSetTime(0, boxes[i].name, 1, new_end_time);
        // This causes compilation error as ObjectSetTime doesn't exist in MQL5
        
        // Correct fix: Use ObjectMove to update the rectangle's second anchor point
        ObjectMove(0, boxes[i].name, 1, new_end_time, boxes[i].price2);
    }
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]) {
    
    // Update boxes to extend them to current time
    UpdateBoxes();
    
    return(rates_total);
}