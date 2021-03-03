import 'package:flutter/material.dart';
import 'package:openfoodfacts/utils/PnnsGroups.dart';
import 'package:provider/provider.dart';
import 'package:smooth_app/pages/scan_page.dart';
import 'package:smooth_app/database/dao_product_list.dart';
import 'package:smooth_app/database/dao_product.dart';
import 'package:smooth_app/pages/choose_page.dart';
import 'package:smooth_app/pages/profile_page.dart';
import 'package:smooth_app/pages/list_page.dart';
import 'package:smooth_app/pages/product_list_button.dart';
import 'package:smooth_app/pages/pantry_list_page.dart';
import 'package:smooth_app/pages/pantry_button.dart';
import 'package:smooth_app/temp/user_preferences.dart';
import 'package:smooth_app/database/local_database.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:smooth_app/data_models/product_list.dart';
import 'package:smooth_app/data_models/pantry.dart';
import 'package:smooth_app/bottom_sheet_views/user_preferences_view.dart';
import 'package:openfoodfacts/model/Attribute.dart';
import 'package:smooth_app/data_models/user_preferences_model.dart';
import 'package:smooth_app/themes/smooth_theme.dart';
import 'package:smooth_app/cards/product_cards/product_list_preview.dart';
import 'package:openfoodfacts/model/Product.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:smooth_app/pages/product_page.dart';
import 'package:smooth_ui_library/widgets/smooth_product_image.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String _TRANSLATE_ME_SEARCHING = 'Searching...';
  static const String _TRANSLATE_ME_PANTRIES = 'My pantries';
  static const String _TRANSLATE_ME_SHOPPINGS = 'My shopping lists';
  static const String _TRANSLATE_ME_EMPTY = 'Empty!';

  static const ColorDestination _COLOR_DESTINATION_FOR_ICON =
      ColorDestination.SURFACE_FOREGROUND;

  DaoProductList _daoProductList;
  DaoProduct _daoProduct;

  final TextEditingController _searchController = TextEditingController();

  bool _visibleCloseButton = false;

  Future<List<Product>> _search(String pattern) async {
    if (pattern.isNotEmpty) {
      _visibleCloseButton = true;
    } else {
      _visibleCloseButton = false;
    }
    setState(() {});
    final List<Product> _returnProducts =
        await _daoProduct.getSuggestions(pattern, 3);
    print('${_returnProducts.length} products locally found with $pattern:');
    return _returnProducts;
  }

  @override
  Widget build(BuildContext context) {
    final LocalDatabase localDatabase = context.watch<LocalDatabase>();
    final UserPreferences userPreferences = context.watch<UserPreferences>();
    final UserPreferencesModel userPreferencesModel =
        context.watch<UserPreferencesModel>();
    _daoProductList = DaoProductList(localDatabase);
    _daoProduct = DaoProduct(localDatabase);
    final ThemeData themeData = Theme.of(context);
    final ColorScheme colorScheme = themeData.colorScheme;
    final bool mlKitState = userPreferences.getMlKitState();
    final Color notYetColor = SmoothTheme.getColor(
      colorScheme,
      Colors.grey,
      ColorDestination.SURFACE_BACKGROUND,
    );
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const <Widget>[
            Icon(Icons.pets),
            SizedBox(width: 8.0),
            Text('Smoothie'),
          ],
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push<dynamic>(
                context,
                MaterialPageRoute<dynamic>(
                  builder: (BuildContext context) => ProfilePage(),
                ),
              );
              setState(() {});
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            //Search
            StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.search,
                      color: SmoothTheme.getColor(
                        colorScheme,
                        Colors.red,
                        _COLOR_DESTINATION_FOR_ICON,
                      ),
                    ),
                    trailing: AnimatedOpacity(
                      opacity: _visibleCloseButton ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 80),
                      child: IgnorePointer(
                        ignoring: !_visibleCloseButton,
                        child: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              FocusScope.of(context).unfocus();
                              _searchController.text = '';
                              _visibleCloseButton = false;
                            });
                          },
                        ),
                      ),
                    ),
                    title: TypeAheadFormField<Product>(
                      textFieldConfiguration: TextFieldConfiguration(
                        controller: _searchController,
                        autofocus: false,
                        decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'What are you looking for?'),
                      ),
                      hideOnEmpty: true,
                      hideOnLoading: true,
                      suggestionsCallback: (String value) async =>
                          _search(value),
                      transitionBuilder: (BuildContext context,
                          Widget suggestionsBox,
                          AnimationController controller) {
                        return suggestionsBox;
                      },
                      itemBuilder: (BuildContext context, Product suggestion) {
                        return ListTile(
                          title: Text(suggestion.productName),
                          leading: SmoothProductImage(
                            product: suggestion,
                          ),
                        );
                      },
                      onSuggestionSelected: (Product suggestion) {
                        Navigator.push<dynamic>(
                          context,
                          MaterialPageRoute<dynamic>(
                            builder: (BuildContext context) => ProductPage(
                              product: suggestion,
                            ),
                          ),
                        );
                      },
                      // TODO(m123-dev): add fullscreen search page,
                      //onSaved: (value) => ,
                    ),
                  ),
                );
              },
            ),

            _getProductListCard(
              <String>[ProductList.LIST_TYPE_USER_DEFINED],
              'My lists',
              Icon(
                Icons.list,
                color: SmoothTheme.getColor(
                  colorScheme,
                  Colors.purple,
                  _COLOR_DESTINATION_FOR_ICON,
                ),
              ),
            ),
            _getPantryCard(userPreferences, _daoProduct, PantryType.PANTRY),
            _getPantryCard(userPreferences, _daoProduct, PantryType.SHOPPING),
            _getRankingPreferences(userPreferencesModel, userPreferences),
            ProductListPreview(
              daoProductList: _daoProductList,
              productList: ProductList(
                listType: ProductList.LIST_TYPE_HISTORY,
                parameters: '',
              ),
              nbInPreview: 5,
            ),
            Card(
              child: ListTile(
                onTap: () async {
                  await Navigator.push<dynamic>(
                    context,
                    MaterialPageRoute<dynamic>(
                      builder: (BuildContext context) => ChoosePage(),
                    ),
                  );
                  setState(() {});
                },
                leading: Icon(
                  Icons.fastfood,
                  color: SmoothTheme.getColor(
                    colorScheme,
                    Colors.orange,
                    _COLOR_DESTINATION_FOR_ICON,
                  ),
                ),
                subtitle: const Text('Food category search'),
                title: Text(
                  '${PnnsGroup1.BEVERAGES.name}'
                  ', ${PnnsGroup1.CEREALS_AND_POTATOES.name}'
                  ', ${PnnsGroup1.COMPOSITE_FOODS.name}'
                  ', ${PnnsGroup1.FAT_AND_SAUCES.name}'
                  ', ${PnnsGroup1.FISH_MEAT_AND_EGGS.name}'
                  ', ...',
                  style: Theme.of(context).textTheme.subtitle2,
                ),
              ),
            ),
            _getProductListCard(
              <String>[
                ProductList.LIST_TYPE_HTTP_SEARCH_GROUP,
                ProductList.LIST_TYPE_HTTP_SEARCH_KEYWORDS,
                ProductList.LIST_TYPE_HTTP_SEARCH_CATEGORY,
              ],
              'Search history',
              Icon(
                Icons.youtube_searched_for,
                color: SmoothTheme.getColor(
                  colorScheme,
                  Colors.yellow,
                  _COLOR_DESTINATION_FOR_ICON,
                ),
              ),
            ),
            Card(
              color: notYetColor,
              child: const ListTile(
                leading: Icon(
                  Icons.score,
                ),
                title: Text('Your current score: 14 points'),
                subtitle: Text('The next level is at 20 points'),
              ),
            ),
            Card(
              color: notYetColor,
              child: const ListTile(
                leading: Icon(
                  Icons.build,
                ),
                title: Text('Contribute'),
                subtitle: Text('Help us list more and more foods!'),
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push<Widget>(
            context,
            MaterialPageRoute<Widget>(
              builder: (BuildContext context) => ScanPage(
                contributionMode: false,
                mlKit: mlKitState,
              ),
            ),
          );
          setState(() {});
        },
        child: SvgPicture.asset(
          'assets/actions/scanner_alt_2.svg',
          height: 25,
          color: colorScheme.onSecondary,
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Widget _getProductListCard(
    final List<String> typeFilter,
    final String title,
    final Icon leadingIcon,
  ) =>
      FutureBuilder<List<ProductList>>(
        future: _daoProductList.getAll(
          limit: 5,
          withStats: false,
          reverse: true,
          typeFilter: typeFilter,
        ),
        builder: (
          final BuildContext context,
          final AsyncSnapshot<List<ProductList>> snapshot,
        ) {
          if (snapshot.connectionState == ConnectionState.done) {
            final List<ProductList> list = snapshot.data;
            List<Widget> cards;
            final bool empty = list == null || list.isEmpty;
            if (empty) {
              cards = null;
            } else {
              cards = <Widget>[];
              for (final ProductList item in list) {
                cards.add(ProductListButton(item, _daoProductList));
              }
            }
            return Card(
              child: Column(
                children: <Widget>[
                  ListTile(
                    onTap: () async {
                      await Navigator.push<dynamic>(
                        context,
                        MaterialPageRoute<dynamic>(
                          builder: (BuildContext context) => ListPage(
                            typeFilter: typeFilter,
                            title: title,
                          ),
                        ),
                      );
                      setState(() {});
                    },
                    leading: leadingIcon,
                    subtitle: empty ? const Text(_TRANSLATE_ME_EMPTY) : null,
                    title: Text(title,
                        style: Theme.of(context).textTheme.subtitle2),
                  ),
                  if (!empty)
                    Wrap(
                      direction: Axis.horizontal,
                      children: cards,
                      spacing: 8.0,
                    ),
                ],
              ),
            );
          }
          return Card(
            child: ListTile(
              leading: const CircularProgressIndicator(),
              title: Text(title),
              subtitle: Text(
                _TRANSLATE_ME_SEARCHING,
                style: Theme.of(context).textTheme.subtitle2,
              ),
            ),
          );
        },
      );

  Widget _getRankingPreferences(
    final UserPreferencesModel userPreferencesModel,
    final UserPreferences userPreferences,
  ) {
    final List<String> orderedVariables =
        userPreferencesModel.getOrderedVariables(userPreferences);
    final List<Widget> attributes = <Widget>[];
    final Map<String, MaterialColor> colors = <String, MaterialColor>{
      'important': Colors.green,
      'very_important': Colors.orange,
      'mandatory': Colors.red,
    };

    final Function onTap = () => UserPreferencesView.showModal(context);
    for (final String variable in orderedVariables) {
      final Attribute attribute =
          userPreferencesModel.getReferenceAttribute(variable);
      final PreferencesValue importance =
          userPreferencesModel.getPreferencesValue(
        variable,
        userPreferences,
      );
      attributes.add(
        ElevatedButton(
          onPressed: () => onTap(),
          child: Text(
            '${attribute.name}',
            style: TextStyle(
              color: SmoothTheme.getColor(
                Theme.of(context).colorScheme,
                colors[importance.id],
                ColorDestination.BUTTON_FOREGROUND,
              ),
            ),
          ),
          style: ElevatedButton.styleFrom(
            primary: SmoothTheme.getColor(
              Theme.of(context).colorScheme,
              colors[importance.id],
              ColorDestination.BUTTON_BACKGROUND,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32.0),
            ),
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: () => onTap(),
      child: Card(
        child: Column(
          children: <Widget>[
            ListTile(
              leading: Icon(
                Icons.bar_chart,
                color: SmoothTheme.getColor(
                  Theme.of(context).colorScheme,
                  Colors.green,
                  _COLOR_DESTINATION_FOR_ICON,
                ),
              ),
              subtitle: attributes.isEmpty
                  ? const Text('Nothing set for the moment')
                  : null,
              title: Text(
                'Food ranking parameters',
                style: Theme.of(context).textTheme.subtitle2,
              ),
            ),
            Wrap(
              direction: Axis.horizontal,
              children: attributes,
              spacing: 8.0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _getPantryCard(
    final UserPreferences userPreferences,
    final DaoProduct daoProduct,
    final PantryType pantryType,
  ) =>
      FutureBuilder<List<Pantry>>(
        future: Pantry.getAll(userPreferences, daoProduct, pantryType),
        builder: (
          final BuildContext context,
          final AsyncSnapshot<List<Pantry>> snapshot,
        ) {
          final String title = pantryType == PantryType.PANTRY
              ? _TRANSLATE_ME_PANTRIES
              : _TRANSLATE_ME_SHOPPINGS;
          final IconData iconData = pantryType == PantryType.PANTRY
              ? Icons.home
              : Icons.shopping_cart;
          final MaterialColor materialColor =
              pantryType == PantryType.PANTRY ? Colors.orange : Colors.blueGrey;
          if (snapshot.connectionState == ConnectionState.done) {
            final List<Pantry> pantries = snapshot.data;
            final List<Widget> cards = <Widget>[];
            for (int index = 0; index < pantries.length; index++) {
              cards.add(PantryButton(pantries, index));
            }
            return Card(
              child: Column(
                children: <Widget>[
                  ListTile(
                    onTap: () async {
                      await Navigator.push<dynamic>(
                        context,
                        MaterialPageRoute<dynamic>(
                          builder: (BuildContext context) => PantryListPage(
                            title,
                            pantries,
                            pantryType,
                          ),
                        ),
                      );
                      setState(() {});
                    },
                    leading: Icon(
                      iconData,
                      color: SmoothTheme.getColor(
                        Theme.of(context).colorScheme,
                        materialColor,
                        _COLOR_DESTINATION_FOR_ICON,
                      ),
                    ),
                    subtitle:
                        cards.isEmpty ? const Text(_TRANSLATE_ME_EMPTY) : null,
                    title: Text(title,
                        style: Theme.of(context).textTheme.subtitle2),
                  ),
                  if (cards.isNotEmpty)
                    Wrap(
                      direction: Axis.horizontal,
                      children: cards,
                      spacing: 8.0,
                    ),
                ],
              ),
            );
          }
          return Card(
            child: ListTile(
              leading: const CircularProgressIndicator(),
              title: Text(title),
              subtitle: Text(
                _TRANSLATE_ME_SEARCHING,
                style: Theme.of(context).textTheme.subtitle2,
              ),
            ),
          );
        },
      );
}
