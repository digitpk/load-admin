// entity/BARCODE.dart

import 'package:floor/floor.dart';

@entity
class Barcode {
  @primaryKey
  final String code;

  final String contact;

  Barcode(this.code, this.contact);
  Map<String, dynamic> toJson() => <String, dynamic>{
        'code': code,
        'contact': contact,
      };
}
