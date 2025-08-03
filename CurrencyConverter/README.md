# Currency Converter Console Application

A simple yet powerful .NET console application that provides dynamic currency conversion using real-time exchange rates.

## Features

- **Real-time Currency Conversion**: Convert between 100+ world currencies using live exchange rates
- **Dynamic Exchange Rates**: Fetches the latest exchange rates from a reliable API
- **Multiple Functionalities**:
  - Currency conversion between any two supported currencies
  - View all supported currencies with their full names
  - Display exchange rates for any base currency
- **User-friendly Interface**: Clean console interface with menu-driven navigation
- **Error Handling**: Robust error handling for network issues and invalid inputs
- **Continuous Operation**: Perform multiple conversions in a single session

## Supported Currencies

The application supports 100+ currencies including:
- USD (US Dollar)
- EUR (Euro)
- GBP (British Pound Sterling)
- JPY (Japanese Yen)
- AUD (Australian Dollar)
- CAD (Canadian Dollar)
- CHF (Swiss Franc)
- CNY (Chinese Yuan)
- And many more...

## Prerequisites

- .NET 8.0 or later
- Internet connection (for fetching live exchange rates)

## Dependencies

- **Newtonsoft.Json**: For JSON serialization/deserialization
- **System.Net.Http**: For making HTTP requests to the exchange rate API

## How to Run

1. **Clone or download the project**
2. **Navigate to the project directory**:
   ```bash
   cd CurrencyConverter
   ```
3. **Build the project**:
   ```bash
   dotnet build
   ```
4. **Run the application**:
   ```bash
   dotnet run
   ```

## Usage

### Main Menu Options

1. **Convert Currency**: Convert an amount from one currency to another
2. **View Supported Currencies**: Display all available currency codes and names
3. **Get Exchange Rates for a Currency**: Show all exchange rates for a specific base currency
4. **Exit**: Close the application

### Currency Conversion Example

```
--- Currency Conversion ---
Enter source currency code (e.g., USD): USD
Enter target currency code (e.g., EUR): EUR
Enter amount to convert: 100

=== Conversion Result ===
100.00 USD = 85.43 EUR
Exchange Rate: 1 USD = 0.8543 EUR
Last Updated: 2025-08-03
```

### Exchange Rates Example

```
--- Exchange Rates ---
Enter base currency code (e.g., USD): USD

Exchange rates for USD (Base: USD)
Last Updated: 2025-08-03
====================================
1 USD = 0.8543 EUR (Euro)
1 USD = 0.7821 GBP (British Pound Sterling)
1 USD = 110.25 JPY (Japanese Yen)
1 USD = 1.3456 CAD (Canadian Dollar)
...
```

## API Information

This application uses the **ExchangeRate-API** (https://api.exchangerate-api.com) which provides:
- Free access to exchange rate data
- Real-time currency conversion rates
- Support for 100+ currencies
- Reliable uptime and performance

## Features in Detail

### 1. Dynamic Currency Conversion
- Fetches real-time exchange rates from external API
- Supports conversion between any two currencies
- Displays conversion results with exchange rate information
- Shows last update timestamp

### 2. Currency Support
- Comprehensive list of world currencies
- Currency code validation
- Full currency names for better user experience

### 3. Error Handling
- Network error handling for API connectivity issues
- Input validation for currency codes and amounts
- Graceful error messages for better user experience

### 4. User Experience
- Clean, menu-driven interface
- Pagination for long lists (currencies/exchange rates)
- Continuous operation with session management
- Clear output formatting

## Code Structure

```
CurrencyConverter/
├── Program.cs              # Main application logic
├── CurrencyConverter.csproj # Project configuration
└── README.md               # Documentation
```

### Key Classes

- **Program**: Main class containing all application logic
- **ExchangeRateData**: Data model for API response deserialization

### Key Methods

- `ShowMainMenu()`: Displays main menu and handles user navigation
- `ConvertCurrency()`: Handles currency conversion functionality
- `ShowSupportedCurrencies()`: Lists all supported currencies
- `ShowExchangeRates()`: Displays exchange rates for a base currency
- `GetExchangeRates()`: Fetches exchange rate data from API
- `GetCurrencyNames()`: Returns currency code to name mappings

## Customization

### Adding New Currency Names
Update the `GetCurrencyNames()` method to add more currency mappings:

```csharp
{"XXX", "Your Currency Name"},
```

### Changing API Provider
Modify the `BASE_URL` constant and update the `ExchangeRateData` class to match the new API's response format.

### Adding Historical Data
Extend the application to support historical exchange rates by modifying API endpoints and adding date selection functionality.

## Limitations

- Requires internet connection for real-time data
- Free API may have rate limits (usually sufficient for personal use)
- Exchange rates are for informational purposes only

## Future Enhancements

- [ ] Historical exchange rate data
- [ ] Currency trend analysis
- [ ] Favorite currency pairs
- [ ] Configuration file for API settings
- [ ] Cached exchange rates for offline use
- [ ] GUI version using WPF or Windows Forms

## License

This project is open source and available under the MIT License.

## Troubleshooting

### Common Issues

1. **Network Connectivity Error**
   - Check your internet connection
   - Verify the API endpoint is accessible

2. **Invalid Currency Code**
   - Use standard 3-letter ISO currency codes (USD, EUR, GBP, etc.)
   - Check the supported currencies list

3. **API Response Error**
   - The free API might have rate limits
   - Try again after a few minutes

### Error Messages

- `Network error`: Check internet connection
- `Data parsing error`: API response format issue
- `Currency conversion failed`: Invalid currency codes
- `Invalid amount entered`: Enter a valid numeric amount

## Contact

For questions, suggestions, or issues, please create an issue in the project repository.