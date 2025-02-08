
import 'package:clear_tool/utils/app_utils.dart';

const int baseOnScreenW = 360;
extension AutoFontSize on int {
  double? get autoSize {
    return (AppUtils.screenW / baseOnScreenW * this);
  }

} 