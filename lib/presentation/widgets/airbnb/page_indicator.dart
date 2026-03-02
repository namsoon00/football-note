import 'package:flutter/material.dart';
import 'constants.dart';

class AirbnbPageIndicator extends StatelessWidget {
  final int activePage;
  final int total;

  const AirbnbPageIndicator({
    super.key,
    required this.activePage,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        total,
        (index) => Container(
          width: index == activePage ? 22.0 : 10.0,
          height: 10.0,
          margin: const EdgeInsets.only(right: 10.0),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(index == activePage ? 10.0 : 50.0),
            color: index == activePage
                ? AirbnbConstants.primaryColor
                : AirbnbConstants.highlightColor2,
          ),
        ),
      ),
    );
  }
}
