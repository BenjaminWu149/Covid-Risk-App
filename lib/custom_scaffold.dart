import 'package:backdrop/backdrop.dart';
import 'package:backdrop/button.dart';
import 'package:backdrop/scaffold.dart';
import 'package:flutter/material.dart';

/// All code is copied from backdrop

class CustomBackdropScaffold extends BackdropScaffold {
  CustomBackdropScaffold({
    var controller,
    var appBar,
    var backLayer,
    var frontLayer,
    var subHeader,
    var subHeaderAlwaysActive = true,
    var headerHeight,
    var frontLayerBorderRadius = const BorderRadius.only(
      topLeft: Radius.circular(16.0),
      topRight: Radius.circular(16.0),
    ),
    var stickyFrontLayer = false,
    var animationCurve = Curves.easeInOut,
    var resizeToAvoidBottomInset = true,
    var backLayerBackgroundColor,
    var floatingActionButton,
    var inactiveOverlayColor = const Color(0xFFEEEEEE),
    var floatingActionButtonLocation,
    var floatingActionButtonAnimator,
    var onBackLayerConcealed,
    var onBackLayerRevealed,
  }) : super(
            controller: controller,
            appBar: appBar,
            backLayer: backLayer,
            frontLayer: frontLayer,
            subHeader: subHeader,
            subHeaderAlwaysActive: subHeaderAlwaysActive,
            headerHeight: headerHeight,
            frontLayerBorderRadius: frontLayerBorderRadius,
            stickyFrontLayer: stickyFrontLayer,
            animationCurve: animationCurve,
            resizeToAvoidBottomInset: resizeToAvoidBottomInset,
            backLayerBackgroundColor: backLayerBackgroundColor,
            floatingActionButton: floatingActionButton,
            inactiveOverlayColor: inactiveOverlayColor,
            floatingActionButtonLocation: floatingActionButtonLocation,
            floatingActionButtonAnimator: floatingActionButtonAnimator,
            onBackLayerConcealed: onBackLayerConcealed,
            onBackLayerRevealed: onBackLayerRevealed);

  @override
  BackdropScaffoldState createState() => CustomBackdropScaffoldState();
}

class CustomBackdropScaffoldState extends BackdropScaffoldState {
  /// Key for accessing the [ScaffoldState] of [BackdropScaffold]'s internally
  /// used [Scaffold].
  final scaffoldKey = GlobalKey<ScaffoldState>();
  GlobalKey _backLayerKey = GlobalKey(debugLabel: "custombackdrop:backLayer");
  double _backPanelHeight = 0;
  GlobalKey _subHeaderKey = GlobalKey(debugLabel: "custombackdrop:subHeader");
  double _headerHeight = 0;

  /// [AnimationController] used for the backdrop animation.
  ///
  /// Defaults to
  /// ```dart
  /// AnimationController(
  ///         vsync: this, duration: Duration(milliseconds: 200), value: 1.0)
  /// ```

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _backPanelHeight = _getBackPanelHeight();
        _headerHeight = _getHeaderHeight();
      });
    });

    revealBackLayer();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Deprecated. Use [isBackLayerConcealed] instead.
  ///
  /// Wether the back layer is concealed or not.
  @Deprecated("Replace by the use of `isBackLayerConcealed`."
      "This feature was deprecated after v0.3.2.")
  bool get isTopPanelVisible => isBackLayerConcealed;

  /// Wether the back layer is concealed or not.
  bool get isBackLayerConcealed =>
      controller.status == AnimationStatus.completed ||
      controller.status == AnimationStatus.forward;

  /// Deprecated. Use [isBackLayerRevealed] instead.
  ///
  /// Whether the back layer is revealed or not.
  @Deprecated("Replace by the use of `isBackLayerRevealed`."
      "This feature was deprecated after v0.3.2.")
  bool get isBackPanelVisible => isBackLayerRevealed;

  /// Whether the back layer is revealed or not.
  bool get isBackLayerRevealed =>
      controller.status == AnimationStatus.dismissed ||
      controller.status == AnimationStatus.reverse;

  /// Toggles the backdrop functionality.
  ///
  /// If the back layer was concealed, it is animated to the "revealed" state
  /// by this function. If it was revealed, this function will animate it to
  /// the "concealed" state.
  void fling() {
    FocusScope.of(context)?.unfocus();
    if (isBackLayerConcealed) {
      revealBackLayer();
    } else {
      concealBackLayer();
    }
  }

  /// Deprecated. Use [revealBackLayer] instead.
  ///
  /// Animates the back layer to the "revealed" state.
  @Deprecated("Replace by the use of `revealBackLayer`."
      "This feature was deprecated after v0.3.2.")
  void showBackLayer() => revealBackLayer();

  /// Animates the back layer to the "revealed" state.
  void revealBackLayer() {
    if (isBackLayerConcealed) {
      controller.animateBack(-1.0);
      widget.onBackLayerRevealed?.call();
    }
  }

  /// Deprecated. Use [concealBackLayer] instead.
  ///
  /// Animates the back layer to the "concealed" state.
  @Deprecated("Replace by the use of `concealBackLayer`."
      "This feature was deprecated after v0.3.2.")
  void showFrontLayer() => concealBackLayer();

  /// Animates the back layer to the "concealed" state.
  void concealBackLayer() {
    if (isBackLayerRevealed) {
      controller.animateTo(1.0);
      widget.onBackLayerConcealed?.call();
    }
  }

  double _getHeaderHeight() {
    // if defined then use it
    if (widget.headerHeight != null) return widget.headerHeight;

    // if no subHeader then 32.0
    if (widget.subHeader == null) return 32.0;

    // if subHeader then height of subHeader
    return ((_subHeaderKey.currentContext?.findRenderObject() as RenderBox)
            ?.size
            ?.height) ??
        32.0;
  }

  double _getBackPanelHeight() =>
      ((_backLayerKey.currentContext?.findRenderObject() as RenderBox)
          ?.size
          ?.height) ??
      0.0;

  Animation<RelativeRect> _getPanelAnimation(
      BuildContext context, BoxConstraints constraints) {
    double backPanelHeight, frontPanelHeight;

    if (widget.stickyFrontLayer &&
        _backPanelHeight < constraints.biggest.height - _headerHeight) {
      // height is adapted to the height of the back panel
      backPanelHeight = _backPanelHeight;
      frontPanelHeight = -_backPanelHeight;
    } else {
      // height is set to fixed value defined in widget.headerHeight
      final height = constraints.biggest.height;
      backPanelHeight = height - _headerHeight;
      frontPanelHeight = -backPanelHeight;
    }
    return RelativeRectTween(
      begin: RelativeRect.fromLTRB(0.0, backPanelHeight, 0.0, frontPanelHeight),
      end: RelativeRect.fromLTRB(0.0, 0.0, 0.0, 0.0),
    ).animate(CurvedAnimation(
      parent: controller,
      curve: widget.animationCurve,
    ));
  }

  Widget _buildInactiveLayer(BuildContext context) {
    return Offstage(
      offstage: controller.status == AnimationStatus.completed,
      child: FadeTransition(
        opacity: Tween(begin: 1.0, end: 0.0).animate(controller),
        child: GestureDetector(
          onTap: () => fling(),
          behavior: HitTestBehavior.opaque,
          child: Column(
            children: <Widget>[
              // if subHeaderAlwaysActive then do not apply inactiveOverlayColor for area with _headerHeight
              widget.subHeader != null && widget.subHeaderAlwaysActive
                  ? Container(height: _headerHeight)
                  : Container(),
              Expanded(
                child: Container(
                  color: widget.inactiveOverlayColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackPanel() {
    return FocusScope(
      canRequestFocus: isBackLayerRevealed,
      child: Material(
        color: this.widget.backLayerBackgroundColor ??
            Theme.of(context).primaryColor,
        child: Column(
          children: <Widget>[
            Flexible(
                key: _backLayerKey, child: widget.backLayer ?? Container()),
          ],
        ),
      ),
    );
  }

  Widget _buildFrontPanel(BuildContext context) {
    return Material(
      elevation: 1.0,
      borderRadius: widget.frontLayerBorderRadius,
      child: ClipRRect(
        borderRadius: widget.frontLayerBorderRadius,
        child: Stack(
          children: <Widget>[
            Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // subHeader
                DefaultTextStyle(
                  key: _subHeaderKey,
                  style: Theme.of(context).textTheme.subtitle1,
                  child: widget.subHeader ?? Container(),
                ),
                // frontLayer
                Flexible(child: widget.frontLayer),
              ],
            ),
            //_buildInactiveLayer(context),
          ],
        ),
      ),
    );
  }

  Future<bool> _willPopCallback(BuildContext context) async {
    if (isBackLayerConcealed) {
      revealBackLayer();
      return false;
    }
    return true;
  }

  Widget _buildBody(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _willPopCallback(context),
      child: Scaffold(
        key: scaffoldKey,
        floatingActionButtonLocation: this.widget.floatingActionButtonLocation,
        floatingActionButtonAnimator: this.widget.floatingActionButtonAnimator,
        appBar: widget.appBar ??
            AppBar(
              title: widget.title,
              actions: widget.iconPosition == BackdropIconPosition.action
                  ? <Widget>[BackdropToggleButton()] + widget.actions
                  : widget.actions,
              elevation: 0.0,
              leading: widget.iconPosition == BackdropIconPosition.leading
                  ? BackdropToggleButton()
                  : null,
            ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              child: Stack(
                children: <Widget>[
                  _buildBackPanel(),
                  PositionedTransition(
                    rect: _getPanelAnimation(context, constraints),
                    child: _buildFrontPanel(context),
                  ),
                ],
              ),
            );
          },
        ),
        floatingActionButton: this.widget.floatingActionButton,
        resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Backdrop(
      data: this,
      child: Builder(
        builder: (context) => _buildBody(context),
      ),
    );
  }
}
