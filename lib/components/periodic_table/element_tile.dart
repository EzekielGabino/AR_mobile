import 'package:flutter/material.dart';
import 'package:scilense_ar_mobile/models/element.dart';
import 'package:scilense_ar_mobile/screens/chemistry_screens/periodic_table/element_detail_screen.dart';

class ElementTile extends StatelessWidget {
  final ElementData element;
  final double tileSize;

  const ElementTile({super.key, required this.element, this.tileSize = 50});

  Color getCategoryColor() {
    final cat = element.category.toLowerCase().trim();

    switch (cat) {
      case "alkali metal":
      case "alkali":
        return Colors.red.shade300;

      case "alkaline earth metal":
      case "alkaline":
        return Colors.orange.shade300;

      case "transition metal":
      case "transition":
        return Colors.amber.shade500;

      case "post-transition metal":
      case "post-transition":
        return Colors.lightBlue.shade300;

      case "metalloid":
        return Colors.green.shade400;

      case "diatomic nonmetal":
      case "polyatomic nonmetal":
      case "reactive nonmetal":
      case "nonmetal":
        return Colors.teal.shade400;

      case "halogen":
        return Colors.purple.shade300;

      case "noble gas":
        return Colors.pink.shade300;

      case "lanthanide":
        return Colors.cyan.shade400;

      case "actinide":
        return Colors.deepPurple.shade300;

      default:
        return Colors.blueGrey.shade300;
    }
  }

  @override
  Widget build(BuildContext context) {
    final atomicNumberSize = tileSize * 0.13;
    final symbolSize = tileSize * 0.30;
    final nameSize = tileSize * 0.10;
    final massSize = tileSize * 0.09;

    return SizedBox(
      width: tileSize,
      height: tileSize,
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.all(1),
        color: getCategoryColor(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ElementDetailScreen(element: element),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Atomic Number
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    element.atomicNumber.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: atomicNumberSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Symbol
                Text(
                  element.symbol,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: symbolSize,
                    height: 1,
                  ),
                ),

                // Name
                Text(
                  element.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: nameSize,
                    height: 1,
                  ),
                ),

                // Atomic Mass
                Text(
                  element.atomicMass.toStringAsFixed(3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: massSize,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
