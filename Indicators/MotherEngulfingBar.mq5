//+------------------------------------------------------------------+
//|                                         MotherEngulfingBar.mq5    |
//|                                  Copyright 2024, Martingle-EA    |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Martingle-EA"
#property link      ""
#property version   "1.00"
#property indicator_chart_window
#property indicator_plots 0

//--- Input parameters
input int                X = 5;                      // จำนวนแท่งก่อนหน้าที่ใช้เทียบ
input int                ExtendBars = 5;             // จำนวนแท่งที่ยืดกรอบไปทางขวา
input int                MaxBarsBack = 999999;       // จำนวนแท่งย้อนหลังที่คำนวณ
input int                MaxBoxes = 999;             // จำนวนกรอบสูงสุดบนกราฟ

//--- Box styling parameters
input color              BullBoxColor = clrGreen;    // สีกรอบฝั่งขึ้น
input color              BearBoxColor = clrRed;      // สีกรอบฝั่งลง
input int                BoxWidth = 2;               // ความหนาเส้น
input ENUM_LINE_STYLE    BoxStyle = STYLE_DASH;      // รูปแบบเส้น
input bool               EnableFill = true;          // เปิดการเติมสีกรอบ
input int                FillTransparency = 30;      // ความโปร่งใส (0-100)

//--- Alert parameters
input bool               EnableAlerts = true;        // เปิดการแจ้งเตือน
input bool               AlertPopup = true;          // แจ้งเตือนแบบ popup
input bool               AlertSound = true;          // แจ้งเตือนเสียง
input bool               AlertPush = true;           // แจ้งเตือน push notification
input bool               AlertEmail = true;          // แจ้งเตือน email

//--- Global variables
struct BoxInfo
{
    long        chart_id;
    string      name;
    datetime    time1, time2;
    double      price1, price2;
    color       box_color;
    bool        is_bullish;
    int         extend_count;
    bool        is_active;
};

BoxInfo boxes[];
int     box_count = 0;
string  indicator_prefix = "MotherEngulfingBar_";
int     last_calculated = 0;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
    //--- Validate input parameters
    if(X <= 0)
    {
        Print("Error: X must be greater than 0");
        return(INIT_PARAMETERS_INCORRECT);
    }
    
    if(ExtendBars <= 0)
    {
        Print("Error: ExtendBars must be greater than 0");
        return(INIT_PARAMETERS_INCORRECT);
    }
    
    if(MaxBoxes <= 0)
    {
        Print("Error: MaxBoxes must be greater than 0");
        return(INIT_PARAMETERS_INCORRECT);
    }
    
    //--- Initialize arrays
    ArrayResize(boxes, MaxBoxes);
    
    //--- Indicator name
    IndicatorSetString(INDICATOR_SHORTNAME, "Mother Engulfing Bar");
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                      |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    //--- Remove all objects created by indicator
    RemoveAllBoxes();
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
                const int &spread[])
{
    //--- Check if we have enough bars
    if(rates_total < X + 2)
        return(0);
    
    //--- Calculate start position
    int start = MathMax(prev_calculated - 1, X + 1);
    if(start >= rates_total - 1)
        start = rates_total - 2; // Don't process current bar
    
    //--- Main calculation loop (only on closed bars)
    for(int i = start; i < rates_total - 1; i++)
    {
        //--- Check for Mother Engulfing Bar pattern
        if(IsMotherEngulfingBar(i, high, low, close))
        {
            //--- Determine if bullish or bearish
            bool is_bullish = close[i] > close[i+1];
            
            //--- Create new box
            CreateNewBox(i, time, high, low, is_bullish);
            
            //--- Send alert if enabled and this is a new signal
            if(EnableAlerts && i == rates_total - 2) // Only alert on the latest closed bar
            {
                SendAlert(is_bullish, time[i]);
            }
        }
    }
    
    //--- Update existing boxes
    UpdateBoxes(rates_total - 1, time, high, low);
    
    return(rates_total);
}

//+------------------------------------------------------------------+
//| Check if current bar is Mother Engulfing Bar                    |
//+------------------------------------------------------------------+
bool IsMotherEngulfingBar(int current_bar, const double &high[], const double &low[], const double &close[])
{
    //--- Get current bar values
    double current_high = high[current_bar];
    double current_low = low[current_bar];
    double current_close = close[current_bar];
    
    //--- Find max/min values in X previous bars (excluding current bar)
    double max_high = DBL_MIN;
    double min_low = DBL_MAX;
    double max_close = DBL_MIN;
    double min_close = DBL_MAX;
    
    for(int i = current_bar + 1; i <= current_bar + X; i++)
    {
        if(high[i] > max_high) max_high = high[i];
        if(low[i] < min_low) min_low = low[i];
        if(close[i] > max_close) max_close = close[i];
        if(close[i] < min_close) min_close = close[i];
    }
    
    //--- Check bullish Mother Engulfing Bar conditions
    bool bullish_condition = (current_high > max_high) && (current_close > max_close);
    
    //--- Check bearish Mother Engulfing Bar conditions  
    bool bearish_condition = (current_low < min_low) && (current_close < min_close);
    
    return (bullish_condition || bearish_condition);
}

//+------------------------------------------------------------------+
//| Create new box                                                   |
//+------------------------------------------------------------------+
void CreateNewBox(int bar_index, const datetime &time[], const double &high[], const double &low[], bool is_bullish)
{
    //--- Remove oldest box if we've reached the maximum
    if(box_count >= MaxBoxes)
    {
        RemoveBox(0);
        ShiftBoxArray();
    }
    
    //--- Get box coordinates
    datetime start_time = time[bar_index];
    // Initially set end time to current bar, will be extended in UpdateBoxes
    datetime end_time = time[bar_index];
    double upper_price = high[bar_index];
    double lower_price = low[bar_index];
    
    //--- Create unique box name
    string box_name = indicator_prefix + "Box_" + IntegerToString(bar_index) + "_" + IntegerToString(GetTickCount());
    
    //--- Select box color
    color box_color = is_bullish ? BullBoxColor : BearBoxColor;
    
    //--- Create rectangle object
    if(!ObjectCreate(0, box_name, OBJ_RECTANGLE, 0, start_time, upper_price, end_time, lower_price))
    {
        Print("Error creating box: ", GetLastError());
        return;
    }
    
    //--- Set box properties
    ObjectSetInteger(0, box_name, OBJPROP_COLOR, box_color);
    ObjectSetInteger(0, box_name, OBJPROP_STYLE, BoxStyle);
    ObjectSetInteger(0, box_name, OBJPROP_WIDTH, BoxWidth);
    ObjectSetInteger(0, box_name, OBJPROP_BACK, false);
    ObjectSetInteger(0, box_name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, box_name, OBJPROP_SELECTED, false);
    ObjectSetInteger(0, box_name, OBJPROP_HIDDEN, true);
    
    //--- Set fill properties if enabled
    if(EnableFill)
    {
        ObjectSetInteger(0, box_name, OBJPROP_FILL, true);
        color fill_color = box_color;
        ObjectSetInteger(0, box_name, OBJPROP_BGCOLOR, fill_color);
        ObjectSetInteger(0, box_name, OBJPROP_TRANSPARENCY, FillTransparency);
    }
    
    //--- Store box information
    boxes[box_count].chart_id = ChartID();
    boxes[box_count].name = box_name;
    boxes[box_count].time1 = start_time;
    boxes[box_count].time2 = end_time;
    boxes[box_count].price1 = upper_price;
    boxes[box_count].price2 = lower_price;
    boxes[box_count].box_color = box_color;
    boxes[box_count].is_bullish = is_bullish;
    boxes[box_count].extend_count = 0;
    boxes[box_count].is_active = true;
    
    box_count++;
    
    //--- Redraw chart
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| Update existing boxes                                            |
//+------------------------------------------------------------------+
void UpdateBoxes(int current_bar, const datetime &time[], const double &high[], const double &low[])
{
    for(int i = 0; i < box_count; i++)
    {
        if(!boxes[i].is_active) continue;
        
        //--- Check if price has broken the box
        double current_high = high[current_bar];
        double current_low = low[current_bar];
        
        bool price_broken = false;
        
        if(boxes[i].is_bullish)
        {
            // For bullish boxes, check if price went below the lower boundary
            if(current_low < boxes[i].price2)
                price_broken = true;
        }
        else
        {
            // For bearish boxes, check if price went above the upper boundary  
            if(current_high > boxes[i].price1)
                price_broken = true;
        }
        
        //--- If price broken or extend limit reached, stop extending
        if(price_broken || boxes[i].extend_count >= ExtendBars)
        {
            boxes[i].is_active = false;
            continue;
        }
        
        //--- Extend the box to the right (future bars)
        datetime new_end_time = time[current_bar];
        ObjectSetInteger(0, boxes[i].name, OBJPROP_TIME, 1, new_end_time);
        boxes[i].time2 = new_end_time;
        boxes[i].extend_count++;
    }
    
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| Send alert                                                       |
//+------------------------------------------------------------------+
void SendAlert(bool is_bullish, datetime signal_time)
{
    string message = "Mother Engulfing Bar " + (is_bullish ? "BULLISH" : "BEARISH") + 
                    " signal detected on " + Symbol() + " " + EnumToString(Period()) + 
                    " at " + TimeToString(signal_time);
    
    if(AlertPopup)
        Alert(message);
    
    if(AlertSound)
        PlaySound("alert.wav");
    
    if(AlertPush)
        SendNotification(message);
    
    if(AlertEmail)
        SendMail("Mother Engulfing Bar Alert - " + Symbol(), message);
}

//+------------------------------------------------------------------+
//| Remove specific box                                              |
//+------------------------------------------------------------------+
void RemoveBox(int index)
{
    if(index >= 0 && index < box_count)
    {
        ObjectDelete(0, boxes[index].name);
    }
}

//+------------------------------------------------------------------+
//| Remove all boxes                                                 |
//+------------------------------------------------------------------+
void RemoveAllBoxes()
{
    for(int i = 0; i < box_count; i++)
    {
        ObjectDelete(0, boxes[i].name);
    }
    box_count = 0;
}

//+------------------------------------------------------------------+
//| Shift box array after removing oldest box                       |
//+------------------------------------------------------------------+
void ShiftBoxArray()
{
    for(int i = 0; i < box_count - 1; i++)
    {
        boxes[i] = boxes[i + 1];
    }
    box_count--;
}

//+------------------------------------------------------------------+