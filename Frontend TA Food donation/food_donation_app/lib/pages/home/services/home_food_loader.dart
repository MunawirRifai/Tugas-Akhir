import 'package:food_donation_app/services/food_service.dart';

class HomeFoodLoader {
  static Future<List<dynamic>> loadFoods(String token) async {
    return await FoodService.getFoods(token);
  }
}