// dao/person_dao.dart

import 'package:floor/floor.dart';
import 'package:load_admin/model/barcode.dart';

@dao
abstract class BarcodeDao {
  @Query('SELECT * FROM Barcode')
  Future<List<Barcode>> getAllBarcodes();

  @Query('SELECT * FROM Barcode WHERE code = :code')
  Stream<Barcode> findBarcodeById(String code);

  @insert
  Future<void> insertBarcode(Barcode barcode);

  @Query("UPDATE Barcode SET contact = :contact,  WHERE barcode = :barcode")
  Future<void> updateContact(String contact, String barcode);
}
