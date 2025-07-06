import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import '../../utils/validators.dart';

class PhoneInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;
  final String? Function(String?) validator;
  final bool isLoading;

  const PhoneInputWidget({
    Key? key,
    required this.controller,
    required this.onChanged,
    this.validator = Validators.validatePhoneNumber,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize with India's country code
    final initialCountry = PhoneNumber(isoCode: 'IN');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phone Number',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16.0,
          ),
        ),
        SizedBox(height: 8.0),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: AbsorbPointer(
            absorbing: isLoading,
            child: InternationalPhoneNumberInput(
              onInputChanged: (PhoneNumber number) {
                // Make sure to include the "+" before the phone number if it's missing
                final phoneNumber = number.phoneNumber ?? '';
                onChanged(phoneNumber.startsWith('+')
                    ? phoneNumber
                    : '+${phoneNumber}');
              },
              initialValue: initialCountry, // Set initial country to India
              selectorConfig: SelectorConfig(
                selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                setSelectorButtonAsPrefixIcon: true,
                trailingSpace: false,
              ),
              ignoreBlank: false,
              autoValidateMode: AutovalidateMode
                  .onUserInteraction, // Changed to validate as user types
              selectorTextStyle: TextStyle(color: Colors.black),
              textFieldController: controller,
              formatInput: true,
              keyboardType:
                  TextInputType.numberWithOptions(signed: true, decimal: true),
              inputBorder: InputBorder.none,
              onSaved: (PhoneNumber number) {},
              // Remove any validation from here as we'll handle it separately
              spaceBetweenSelectorAndTextField: 0,
              countries: [
                'IN'
              ], // Only allow India for now (you can remove this line to allow all countries)
            ),
          ),
        ),
      ],
    );
  }
}
