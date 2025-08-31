import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A responsive text widget that automatically handles overflow and sizing
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fontSize,
    this.fontWeight,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Get screen width to adjust font size responsively
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 350;
    
    // Calculate responsive font size
    double responsiveFontSize = fontSize ?? style?.fontSize ?? 14;
    if (isSmallScreen) {
      responsiveFontSize = responsiveFontSize * 0.9; // Reduce by 10% on small screens
    }
    responsiveFontSize = responsiveFontSize.sp; // Apply screen util scaling

    TextStyle finalStyle = (style ?? const TextStyle()).copyWith(
      fontSize: responsiveFontSize,
      fontWeight: fontWeight,
      color: color,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Check if text would overflow
        final textPainter = TextPainter(
          text: TextSpan(text: text, style: finalStyle),
          maxLines: maxLines,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout(maxWidth: constraints.maxWidth);

        // If text would overflow, use smaller font or more lines
        if (textPainter.didExceedMaxLines || textPainter.width > constraints.maxWidth) {
          return Text(
            text,
            style: finalStyle.copyWith(fontSize: finalStyle.fontSize! * 0.9),
            textAlign: textAlign ?? TextAlign.start,
            maxLines: maxLines ?? 3,
            overflow: overflow ?? TextOverflow.ellipsis,
          );
        }

        return Text(
          text,
          style: finalStyle,
          textAlign: textAlign ?? TextAlign.start,
          maxLines: maxLines,
          overflow: overflow,
        );
      },
    );
  }
}

/// A responsive container that prevents overflow by adjusting its content
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BoxDecoration? decoration;
  final double? width;
  final double? height;
  final BoxConstraints? constraints;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.decoration,
    this.width,
    this.height,
    this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 350;
    
    // Adjust padding based on screen size
    EdgeInsetsGeometry responsivePadding = padding ?? EdgeInsets.zero;
    if (isSmallScreen && padding != null) {
      responsivePadding = EdgeInsets.fromLTRB(
        padding!.resolve(TextDirection.ltr).left * 0.8,
        padding!.resolve(TextDirection.ltr).top * 0.8,
        padding!.resolve(TextDirection.ltr).right * 0.8,
        padding!.resolve(TextDirection.ltr).bottom * 0.8,
      );
    }

    return Container(
      width: width,
      height: height,
      padding: responsivePadding,
      margin: margin,
      decoration: decoration,
      constraints: constraints ?? BoxConstraints(
        maxWidth: screenSize.width,
        maxHeight: screenSize.height,
      ),
      child: child,
    );
  }
}

/// A responsive row that wraps to column on small screens
class ResponsiveRowColumn extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double breakpoint;

  const ResponsiveRowColumn({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.breakpoint = 350,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < breakpoint) {
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: children,
      );
    } else {
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: children,
      );
    }
  }
}
