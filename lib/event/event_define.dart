class SamePhotoEvent {
  final List<Map<String, dynamic>> assets;
  SamePhotoEvent(this.assets);
}

class BigPhotoEvent {
  final String id;
  BigPhotoEvent(this.id);
}


class ScreenPhotoEvent {
  final List<String> assetsIds;
  ScreenPhotoEvent(this.assetsIds);
}


class RefreshEvent {
}


class AllPhotoLoadFinishEvent {
}
