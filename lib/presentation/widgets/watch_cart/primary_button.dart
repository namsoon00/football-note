import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'constants.dart';

class WatchCartPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const WatchCartPrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54.h,
      child: Material(
        color: WatchCartConstants.primaryColor,
        borderRadius: BorderRadius.circular(16.0),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16.0),
          splashColor: Colors.white.withAlpha(51),
          highlightColor: Colors.white.withAlpha(25),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
