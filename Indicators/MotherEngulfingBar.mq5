// Updated code for MotherEngulfingBar.mq5

// ... (previous code)

// Line 222 - Update ObjectSetInteger to ObjectMove
ObjectMove(0, boxes[i].name, 1, new_end_time, boxes[i].price2);

// ... (subsequent code)