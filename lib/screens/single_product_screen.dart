import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SingleProductScreen extends StatefulWidget {
  final int? id;
  const SingleProductScreen({Key? key, this.id}) : super(key: key);

  @override
  _SingleProductScreenState createState() => _SingleProductScreenState();
}

class _SingleProductScreenState extends State<SingleProductScreen> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  var products;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadProducts();
  }

  void _loadProducts() async {
    QuerySnapshot querySnapshot = await firestore.collection("products").get();
    var alldata = querySnapshot.docs.map((doc) => doc.data()).toList();
    setState(() {
      products = alldata;
    });
    print(products);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(15),
            child: (products == null)
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                : Column(
                    children: [
                      // SizedBox(width: 20,),
                      Container(
                        decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(25)),
                        width: MediaQuery.of(context).size.width,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: SizedBox(
                            child: Image.network(
                              products[widget.id!]["image"],
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 5,
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            products[widget.id!]["name"],
                            style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w600,
                                color: Colors.black45),
                          ),
                          Text(
                            "\$${products[widget.id!]["price"]}",
                            style: TextStyle(
                              color: Colors.black45,
                                fontSize: 20, fontWeight: FontWeight.w700),
                          )
                        ],
                      )
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
