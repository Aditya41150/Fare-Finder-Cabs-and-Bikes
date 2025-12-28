import 'dart:async';
import 'package:flutter/material.dart';
import '../models/place_prediction.dart';
import '../services/places_service.dart';

class LocationAutocomplete extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final IconData prefixIcon;
  final Color iconColor;
  final String? Function(String?)? validator;
  final Function(PlacePrediction) onPlaceSelected;

  const LocationAutocomplete({
    super.key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    required this.prefixIcon,
    required this.iconColor,
    this.validator,
    required this.onPlaceSelected,
  });

  @override
  State<LocationAutocomplete> createState() => _LocationAutocompleteState();
}

class _LocationAutocompleteState extends State<LocationAutocomplete> {
  List<PlacePrediction> _suggestions = [];
  Timer? _debounce;
  bool _isLoading = false;

  // This replaces the old fixed list logic
  void _onQueryChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.length > 2) {
        setState(() => _isLoading = true);

        // Fetches real data from your Node.js server
        final predictions = await PlacesService.getAutocompletePredictions(
          query,
        );

        setState(() {
          _suggestions = predictions;
          _isLoading = false;
        });
      } else {
        setState(() => _suggestions = []);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: widget.controller,
          onChanged: _onQueryChanged,
          validator: widget.validator,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            prefixIcon: Icon(widget.prefixIcon, color: widget.iconColor),
            suffixIcon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      widget.controller.clear();
                      setState(() => _suggestions = []);
                    },
                  ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        if (_suggestions.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 250),
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final prediction = _suggestions[index];
                return ListTile(
                  leading: const Icon(Icons.location_on, size: 20),
                  title: Text(
                    prediction.description,
                  ), // Real address from Google
                  onTap: () {
                    widget.controller.text = prediction.description;
                    widget.onPlaceSelected(prediction);
                    setState(
                      () => _suggestions = [],
                    ); // Hide list after selection
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
