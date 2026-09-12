enum PageId {
  home,
  map,
  analysis,
  cost,
  safety,
  social,
  infra,
  amenities,
  transport,
  saved,
  properties,
  addProperty,
  detail,
  compare,
  report,
  reports,
  account,
  login,
  register,
}

enum Place { kl, penang }

extension PlaceName on Place {
  String get name => this == Place.kl ? '吉隆坡' : '乔治市（槟城）';
  String get short => this == Place.kl ? '吉隆坡' : '乔治市';
  String get area => this == Place.kl ? '吉隆坡联邦直辖区' : '东北县，槟城';
}
