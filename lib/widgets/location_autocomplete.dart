import 'package:flutter/material.dart';
import 'dart:async';
import '../services/places_service.dart';

class LocationAutocomplete extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final IconData prefixIcon;
  final Color iconColor;
  final String? Function(String?)? validator;
  final Function(PlacePrediction)? onPlaceSelected;

  const LocationAutocomplete({
    Key? key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    required this.prefixIcon,
    required this.iconColor,
    this.validator,
    this.onPlaceSelected,
  }) : super(key: key);

  @override
  State<LocationAutocomplete> createState() => _LocationAutocompleteState();
}

class _LocationAutocompleteState extends State<LocationAutocomplete> {
  List<PlacePrediction> _predictions = [];
  bool _isLoading = false;
  Timer? _debounceTimer;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _debounceTimer?.cancel();
    _removeOverlay();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _searchPlaces(widget.controller.text);
    });
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _removeOverlay();
    }
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        _predictions = [];
        _isLoading = false;
      });
      _removeOverlay();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final predictions = await PlacesService.getAutocompletePredictions(query);
      setState(() {
        _predictions = predictions;
        _isLoading = false;
      });
      
      if (predictions.isNotEmpty && _focusNode.hasFocus) {
        _showOverlay();
      } else {
        _removeOverlay();
      }
    } catch (e) {
      setState(() {
        _predictions = [];
        _isLoading = false;
      });
      _removeOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 40,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 60),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _predictions.length,
                itemBuilder: (context, index) {
                  final prediction = _predictions[index];
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.location_on,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                    title: Text(
                      prediction.mainText,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      prediction.secondaryText,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    onTap: () {
                      widget.controller.text = prediction.description;
                      widget.onPlaceSelected?.call(prediction);
                      _removeOverlay();
                      _focusNode.unfocus();
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          prefixIcon: Icon(widget.prefixIcon, color: widget.iconColor),
          suffixIcon: _isLoading
              ? Container(
                  width: 20,
                  height: 20,
                  padding: const EdgeInsets.all(12),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(widget.iconColor),
                  ),
                )
              : widget.controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        widget.controller.clear();
                        _removeOverlay();
                      },
                    )
                  : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        validator: widget.validator,
        onTap: () {
          if (widget.controller.text.isNotEmpty && _predictions.isNotEmpty) {
            _showOverlay();
          }
        },
      ),
    );
  }
}
