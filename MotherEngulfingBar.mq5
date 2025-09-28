// Updated line 222 to use ObjectMove instead of ObjectSetInteger
// Original line: ObjectSetInteger(0, boxes[i].name, OBJPROP_TIME, 1, new_end_time);
ObjectMove(0, boxes[i].name, 1, new_end_time, boxes[i].price2);