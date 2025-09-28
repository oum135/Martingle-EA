# Martingle-EA

## Mother Engulfing Bar MT5 Indicator

This repository contains the **Mother Engulfing Bar** MT5 Indicator that draws boxes around price bars that meet specific engulfing conditions.

### Features

- **Signal Detection**: Identifies bars where both High/Low and Close values exceed the maximum/minimum values of the previous X bars
- **Box Drawing**: Creates visual boxes around signal bars with customizable styling
- **Extension Logic**: Boxes extend to the right for a specified number of bars or until price breaks the box
- **Price Break Detection**: Automatically stops extending boxes when price touches or breaks through them
- **Multiple Alerts**: Supports popup, sound, push notifications, and email alerts
- **Customizable Styling**: Full control over colors, line thickness, style, and transparency

### Installation

1. Copy `MotherEngulfingBar.mq5` to your MT5 `MQL5/Indicators/` folder
2. Compile the indicator in MetaEditor
3. Apply to any chart from the Navigator panel

### Parameters

#### Signal Parameters
- **X** (default: 5): Number of previous bars to compare against
- **ExtendBars** (default: 5): Number of bars to extend boxes to the right
- **MaxBarsBack** (default: 999999): Maximum number of historical bars to calculate
- **MaxBoxes** (default: 999): Maximum number of boxes to display on chart

#### Styling Parameters
- **BullBoxColor** (default: Green): Color for bullish signal boxes
- **BearBoxColor** (default: Red): Color for bearish signal boxes
- **BoxWidth** (default: 2): Line thickness for box borders
- **BoxStyle** (default: Dash): Line style for box borders
- **EnableFill** (default: true): Enable box background fill
- **FillTransparency** (default: 30): Background transparency (0-100%)

#### Alert Parameters
- **EnableAlerts** (default: true): Master switch for all alerts
- **AlertPopup** (default: true): Show popup alerts
- **AlertSound** (default: true): Play sound alerts
- **AlertPush** (default: true): Send push notifications
- **AlertEmail** (default: true): Send email alerts

### Signal Conditions

A Mother Engulfing Bar signal occurs when **both** conditions are met simultaneously:

1. **High/Low Condition**: The current bar's High is greater than the highest High of the previous X bars (for bullish), OR the current bar's Low is lower than the lowest Low of the previous X bars (for bearish)

2. **Close Condition**: The current bar's Close is greater than the highest Close of the previous X bars (for bullish), OR the current bar's Close is lower than the lowest Close of the previous X bars (for bearish)

### Box Behavior

- Boxes are drawn around the High and Low of signal bars
- Boxes extend to the right for the specified number of bars
- Extension stops immediately if price touches or breaks through the box
- All previous boxes remain on the chart when new signals occur
- Boxes use dashed lines with optional background fill

### Alerts

- Alerts are triggered only on closed bars (not on the current forming bar)
- All alert types can be enabled/disabled independently
- Alert messages include symbol, timeframe, and signal direction

### Technical Details

- Compatible with all MT5 symbols and timeframes
- Uses strict comparison operators (> and <, not >= or <=)
- Excludes the current bar from historical comparisons
- Efficient memory management with configurable maximum boxes
- Professional MT5 coding standards and error handling
