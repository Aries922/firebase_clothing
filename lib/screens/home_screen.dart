import 'package:clothing_firebase/screens/single_product_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share/share.dart';

class HomePage extends StatefulWidget {
  @override
  HomePageState createState() => HomePageState();
}

const CURVE_HEIGHT = 100.0;
const AVATAR_RADIUS = CURVE_HEIGHT * 0.8;

class HomePageState extends State<HomePage> {
  FirebaseStorage storage = FirebaseStorage.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  var isSelected = 1;
  String? _linkMessage;
  bool _isCreatingLink = false;

  Future<List<Map<String, dynamic>>> _loadImages() async {
    List<Map<String, dynamic>> files = [];

    final ListResult result = await storage.ref().list();
    final List<Reference> allFiles = result.items;

    await Future.forEach<Reference>(allFiles, (file) async {
      final String fileUrl = await file.getDownloadURL();
      final FullMetadata fileMeta = await file.getMetadata();
      files.add({
        "url": fileUrl,
        "path": file.fullPath,
        // "uploaded_by": fileMeta.customMetadata?['uploaded_by'] ?? 'Nobody',
        // "description":
        //     fileMeta.customMetadata?['description'] ?? 'No description'
      });
    });
    print(files);
    return files;
  }

  var products;
  void _loadProducts() async {
    QuerySnapshot querySnapshot = await firestore.collection("products").get();
    var alldata = querySnapshot.docs.map((doc) => doc.data()).toList();
    setState(() {
      products = alldata;
    });
    print(products);
  }

  Widget tabItem(var pos, var icon, var title) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isSelected = pos;
        });
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.25,
        height: 50,
        alignment: Alignment.center,
        child: Column(
          children: <Widget>[
            Icon(
              icon,
              color: isSelected == pos ? Colors.pink : Colors.black45,
              size: 26,
            ),
            Text(
              title,
              style: TextStyle(
                  color: isSelected == pos ? Colors.pink : Colors.black45,
                  fontSize: 15,
                  fontWeight: FontWeight.w500),
            )
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    initDynamicLinks();

    getImages();
    _loadProducts();
  }

  Future<void> initDynamicLinks() async {
    int? id;

    FirebaseDynamicLinks.instance.onLink(
        onSuccess: (PendingDynamicLinkData? dynamicLink) async {
      final Uri? deepLink = dynamicLink?.link;

      if (deepLink != null) {
        if (deepLink.queryParameters.containsKey('id')) {
          id = int.parse(deepLink.queryParameters['id']!);

          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => SingleProductScreen(
                        id: id,
                      )));
        }
      }
    }, onError: (OnLinkErrorException e) async {
      print('onLinkError');
      print(e.message);
    });

    final PendingDynamicLinkData? data =
        await FirebaseDynamicLinks.instance.getInitialLink();
    final Uri? deepLink = data?.link;

    if (deepLink != null) {
      // ignore: unawaited_futures
      Navigator.pushNamed(context, deepLink.path);
    }
  }

  Future<void> createDynamicLink(bool short, int id) async {
    setState(() {
      _isCreatingLink = true;
    });

    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: 'https://clotingfirebase.page.link',
      link: Uri.parse('https://clotingfirebase.page.link/product/?id=$id'),
      androidParameters: AndroidParameters(
        packageName: 'com.example.clothing_firebase',
        minimumVersion: 0,
      ),
      dynamicLinkParametersOptions: DynamicLinkParametersOptions(
        shortDynamicLinkPathLength: ShortDynamicLinkPathLength.short,
      ),
    );

    Uri url;
    if (short) {
      final ShortDynamicLink shortLink = await parameters.buildShortLink();
      url = shortLink.shortUrl;
    } else {
      url = await parameters.buildUrl();
    }

    setState(() {
      _linkMessage = url.toString();
      _isCreatingLink = false;
    });
  }

  var data;
  getImages() async {
    await _loadImages().then((value) {
      setState(() {
        data = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget label(var text) {
      return Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              text,
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 17),
            ),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                      text: "View all",
                      style: TextStyle(fontSize: 14, color: Colors.grey)),
                  WidgetSpan(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.0),
                      child: Icon(
                        Icons.keyboard_arrow_right,
                        color: Colors.grey,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      );
    }

    return SafeArea(
      child: Scaffold(
        bottomNavigationBar: Container(
          padding: EdgeInsets.all(8),
          margin: EdgeInsets.only(top: 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                  color: Colors.grey,
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: Offset(0, 3.0)),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.only(left: 0.0, right: 0, top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                tabItem(1, Icons.home, "Home"),
                tabItem(2, Icons.local_offer, "Offers"),
                tabItem(3, Icons.person, "Profile"),
              ],
            ),
          ),
        ),
        body: Column(
          children: <Widget>[
            Stack(
              children: <Widget>[
                Container(
                  width: double.infinity,
                  height: 140,
                  child: CustomPaint(painter: _MyPainter()),
                ),
                Container(
                  width: MediaQuery.of(context).size.width,
                  height: 50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          IconButton(
                            icon: Icon(Icons.menu, color: Colors.white),
                            onPressed: () {},
                          ),
                          Text(
                            "Home",
                            style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 20,
                                color: Colors.white),
                          ),
                        ],
                      ),
                      Row(
                        children: <Widget>[
                          IconButton(
                            icon: Icon(Icons.favorite, color: Colors.white),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon:
                                Icon(Icons.shopping_cart, color: Colors.white),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: MediaQuery.of(context).size.width,
                  transform: Matrix4.translationValues(0.0, 60.0, 0.0),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(26)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey,
                              blurRadius: 3.0,
                              spreadRadius: 0.5,
                              // offset: offset,
                            )
                          ]),
                      child: Stack(
                        alignment: Alignment.centerRight,
                        children: <Widget>[
                          TextField(
                              decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  hintText: "Search Here",
                                  contentPadding: EdgeInsets.only(
                                      left: 26.0, bottom: 8.0, right: 50.0),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors.white, width: 0.5),
                                    borderRadius: BorderRadius.circular(26),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors.white, width: 0.5),
                                    borderRadius: BorderRadius.circular(26),
                                  ))),
                          GestureDetector(
                            child: Padding(
                              padding: EdgeInsets.only(right: 16.0),
                              child: Icon(Icons.search, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(left: 16, bottom: 16),
                      child: Text(
                        "Offers",
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 14),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.only(right: 16, left: 16),
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.width * 0.38,
                      child: (data != null)
                          ? PageView(
                              children: [
                                Slider(file: data[0]["url"]),
                                Slider(file: data[1]["url"]),
                                Slider(file: data[2]["url"]),
                                Slider(file: data[3]["url"]),
                                Slider(file: data[4]["url"]),
                                Slider(file: data[5]["url"]),
                              ],
                            )
                          : Center(
                              child: CircularProgressIndicator(),
                            ),
                    ),
                    label("Products"),
                    SizedBox(
                      height: 200,
                      child: (products != null)
                          ? ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: products.length,
                              shrinkWrap: true,
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                  onTap: (){
                                    Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => SingleProductScreen(
                        id: index,
                      )));
                                  },
                                  child: Container(
                                    width:
                                        MediaQuery.of(context).size.width * 0.4,
                                    margin: EdgeInsets.only(left: 16),
                                    child: Stack(
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12.0),
                                              child: Image.network(
                                                  products[index]["image"],
                                                  fit: BoxFit.cover,
                                                  height: 170,
                                                  width: MediaQuery.of(context)
                                                      .size
                                                      .width),
                                            ),
                                            SizedBox(height: 4),
                                            Padding(
                                              padding: EdgeInsets.only(
                                                  left: 4, right: 4),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: <Widget>[
                                                  Text(
                                                    products[index]!["name"],
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500),
                                                  ),
                                                  Text(
                                                      "\$${products[index]!["price"]}",
                                                      style: TextStyle(
                                                          color: Colors.grey,
                                                          fontWeight:
                                                              FontWeight.w500)),
                                                ],
                                              ),
                                            )
                                          ],
                                        ),
                                        Positioned(
                                            right: 0,
                                            child: IconButton(
                                                onPressed: () async {
                                                  await createDynamicLink(
                                                    false,
                                                    index
                                                    ,
                                                  );
                                                  Share.share(_linkMessage!);
                                                },
                                                icon: Icon(
                                                  Icons.share_rounded,
                                                  color: Colors.white,
                                                )))
                                      ],
                                    ),
                                  ),
                                );
                              })
                          : Center(
                              child: CircularProgressIndicator(),
                            ),
                    ),
                    label("Featured"),
                    SizedBox(
                      height: 200,
                      child: (products != null)
                          ? ListView.builder(
                              reverse: true,
                              scrollDirection: Axis.horizontal,
                              itemCount: products.length,
                              shrinkWrap: true,
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                   onTap: (){
                                    Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => SingleProductScreen(
                        id: index,
                      )));
                                  },
                                  child: Container(
                                    width:
                                        MediaQuery.of(context).size.width * 0.4,
                                    margin: EdgeInsets.only(left: 16),
                                    child: Stack(
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12.0),
                                              child: Image.network(
                                                  products[index]["image"],
                                                  fit: BoxFit.cover,
                                                  height: 170,
                                                  width: MediaQuery.of(context)
                                                      .size
                                                      .width),
                                            ),
                                            SizedBox(height: 4),
                                            Padding(
                                              padding: EdgeInsets.only(
                                                  left: 4, right: 4),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: <Widget>[
                                                  Text(
                                                    products[index]!["name"],
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500),
                                                  ),
                                                  Text(
                                                      "\$${products[index]!["price"]}",
                                                      style: TextStyle(
                                                          color: Colors.grey,
                                                          fontWeight:
                                                              FontWeight.w500)),
                                                ],
                                              ),
                                            )
                                          ],
                                        ),
                                        Positioned(
                                            right: 0,
                                            child: IconButton(
                                                onPressed: () async {
                                                  await createDynamicLink(
                                                    false,
                                                    index
                                                    ,
                                                  );
                                                  Share.share(_linkMessage!);
                                                },
                                                icon: Icon(
                                                  Icons.share_rounded,
                                                  color: Colors.white,
                                                )))
                                      ],
                                    ),
                                  ),
                                );
                              })
                          : Center(
                              child: CircularProgressIndicator(),
                            ),
                    ),
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: must_be_immutable

// ignore: must_be_immutable
class Product extends StatelessWidget {
  final Map<String, dynamic>? response;
  final int? length;
  final Function()? onTap;

  const Product({Key? key, this.response, this.length, this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.4,
      margin: EdgeInsets.only(left: 16),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.network(response!["image"],
                    fit: BoxFit.cover,
                    height: 170,
                    width: MediaQuery.of(context).size.width),
              ),
              SizedBox(height: 4),
              Padding(
                padding: EdgeInsets.only(left: 4, right: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      response!["name"],
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text("\$${response!["price"]}",
                        style: TextStyle(
                            color: Colors.grey, fontWeight: FontWeight.w500)),
                  ],
                ),
              )
            ],
          ),
          Positioned(
              right: 0,
              child: IconButton(
                  onPressed: onTap,
                  icon: Icon(
                    Icons.share_rounded,
                    color: Colors.white,
                  )))
        ],
      ),
    );
  }
}

class Slider extends StatelessWidget {
  final String file;

  Slider({Key? key, required this.file}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width - 32,
      child: Card(
        semanticContainer: true,
        clipBehavior: Clip.antiAliasWithSaveLayer,
        elevation: 0,
        margin: EdgeInsets.all(0),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        child: Image.network(file, fit: BoxFit.fill),
      ),
    );
  }
}

class _MyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint();
    paint.style = PaintingStyle.fill;
    paint.color = Colors.pink;

    Path path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
        size.width / 2, size.height, size.width, size.height - 50);
    path.lineTo(size.width, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

List<BoxShadow> defaultBoxShadow({
  Color? shadowColor,
  double? blurRadius,
  double? spreadRadius,
  Offset offset = const Offset(0.0, 0.0),
}) {
  return [];
}
