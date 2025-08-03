using System;
using System.Net.Http;
using System.Threading.Tasks;
using Newtonsoft.Json;
using System.Collections.Generic;

namespace CurrencyConverter
{
    class Program
    {
        private static readonly HttpClient client = new HttpClient();
        private const string BASE_URL = "https://api.exchangerate-api.com/v4/latest/";
        
        static async Task Main(string[] args)
        {
            Console.WriteLine("=================================================");
            Console.WriteLine("          Currency Converter                     ");
            Console.WriteLine("    Dynamic Currency Conversion Console App      ");
            Console.WriteLine("=================================================");
            Console.WriteLine();

            while (true)
            {
                try
                {
                    await ShowMainMenu();
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"An error occurred: {ex.Message}");
                    Console.WriteLine("Please try again.");
                }
                
                Console.WriteLine();
                Console.Write("Do you want to perform another conversion? (y/n): ");
                var continue_choice = Console.ReadLine()?.ToLower();
                if (continue_choice != "y" && continue_choice != "yes")
                {
                    break;
                }
                Console.Clear();
            }
            
            Console.WriteLine("Thank you for using Currency Converter!");
        }

        static async Task ShowMainMenu()
        {
            Console.WriteLine("Choose an option:");
            Console.WriteLine("1. Convert Currency");
            Console.WriteLine("2. View Supported Currencies");
            Console.WriteLine("3. Get Exchange Rates for a Currency");
            Console.WriteLine("4. Exit");
            Console.Write("Enter your choice (1-4): ");
            
            var choice = Console.ReadLine();
            
            switch (choice)
            {
                case "1":
                    await ConvertCurrency();
                    break;
                case "2":
                    await ShowSupportedCurrencies();
                    break;
                case "3":
                    await ShowExchangeRates();
                    break;
                case "4":
                    Environment.Exit(0);
                    break;
                default:
                    Console.WriteLine("Invalid choice. Please try again.");
                    break;
            }
        }

        static async Task ConvertCurrency()
        {
            Console.WriteLine("\n--- Currency Conversion ---");
            
            Console.Write("Enter source currency code (e.g., USD): ");
            var fromCurrency = Console.ReadLine()?.ToUpper();
            
            Console.Write("Enter target currency code (e.g., EUR): ");
            var toCurrency = Console.ReadLine()?.ToUpper();
            
            Console.Write("Enter amount to convert: ");
            if (!decimal.TryParse(Console.ReadLine(), out decimal amount))
            {
                Console.WriteLine("Invalid amount entered.");
                return;
            }

            if (string.IsNullOrEmpty(fromCurrency) || string.IsNullOrEmpty(toCurrency))
            {
                Console.WriteLine("Invalid currency codes entered.");
                return;
            }

            try
            {
                var exchangeData = await GetExchangeRates(fromCurrency);
                if (exchangeData != null && exchangeData.Rates.ContainsKey(toCurrency))
                {
                    var rate = exchangeData.Rates[toCurrency];
                    var convertedAmount = amount * rate;
                    
                    Console.WriteLine();
                    Console.WriteLine("=== Conversion Result ===");
                    Console.WriteLine($"{amount:F2} {fromCurrency} = {convertedAmount:F2} {toCurrency}");
                    Console.WriteLine($"Exchange Rate: 1 {fromCurrency} = {rate:F4} {toCurrency}");
                    Console.WriteLine($"Last Updated: {exchangeData.Date}");
                }
                else
                {
                    Console.WriteLine("Currency conversion failed. Please check your currency codes.");
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error during conversion: {ex.Message}");
            }
        }

        static async Task ShowSupportedCurrencies()
        {
            Console.WriteLine("\n--- Supported Currencies ---");
            
            try
            {
                // Get rates for USD to show all supported currencies
                var exchangeData = await GetExchangeRates("USD");
                if (exchangeData != null)
                {
                    Console.WriteLine("Supported currency codes:");
                    Console.WriteLine();
                    
                    var currencies = GetCurrencyNames();
                    int count = 0;
                    
                    foreach (var currencyCode in exchangeData.Rates.Keys)
                    {
                        var name = currencies.ContainsKey(currencyCode) ? currencies[currencyCode] : "Unknown";
                        Console.WriteLine($"{currencyCode} - {name}");
                        count++;
                        
                        // Pause every 20 currencies for better readability
                        if (count % 20 == 0)
                        {
                            Console.Write("Press any key to continue...");
                            Console.ReadKey();
                            Console.WriteLine();
                        }
                    }
                    
                    Console.WriteLine($"\nTotal supported currencies: {exchangeData.Rates.Count + 1}"); // +1 for base currency
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error retrieving currencies: {ex.Message}");
            }
        }

        static async Task ShowExchangeRates()
        {
            Console.WriteLine("\n--- Exchange Rates ---");
            
            Console.Write("Enter base currency code (e.g., USD): ");
            var baseCurrency = Console.ReadLine()?.ToUpper();
            
            if (string.IsNullOrEmpty(baseCurrency))
            {
                Console.WriteLine("Invalid currency code entered.");
                return;
            }

            try
            {
                var exchangeData = await GetExchangeRates(baseCurrency);
                if (exchangeData != null)
                {
                    Console.WriteLine();
                    Console.WriteLine($"Exchange rates for {baseCurrency} (Base: {exchangeData.Base})");
                    Console.WriteLine($"Last Updated: {exchangeData.Date}");
                    Console.WriteLine("====================================");
                    
                    var currencies = GetCurrencyNames();
                    int count = 0;
                    
                    foreach (var rate in exchangeData.Rates)
                    {
                        var name = currencies.ContainsKey(rate.Key) ? currencies[rate.Key] : "Unknown";
                        Console.WriteLine($"1 {baseCurrency} = {rate.Value:F4} {rate.Key} ({name})");
                        count++;
                        
                        // Pause every 15 rates for better readability
                        if (count % 15 == 0)
                        {
                            Console.Write("Press any key to continue...");
                            Console.ReadKey();
                            Console.WriteLine();
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error retrieving exchange rates: {ex.Message}");
            }
        }

        static async Task<ExchangeRateData?> GetExchangeRates(string baseCurrency)
        {
            try
            {
                Console.WriteLine("Fetching latest exchange rates...");
                var response = await client.GetStringAsync($"{BASE_URL}{baseCurrency}");
                return JsonConvert.DeserializeObject<ExchangeRateData>(response);
            }
            catch (HttpRequestException ex)
            {
                Console.WriteLine($"Network error: {ex.Message}");
                return null;
            }
            catch (JsonException ex)
            {
                Console.WriteLine($"Data parsing error: {ex.Message}");
                return null;
            }
        }

        static Dictionary<string, string> GetCurrencyNames()
        {
            return new Dictionary<string, string>
            {
                {"USD", "US Dollar"},
                {"EUR", "Euro"},
                {"GBP", "British Pound Sterling"},
                {"JPY", "Japanese Yen"},
                {"AUD", "Australian Dollar"},
                {"CAD", "Canadian Dollar"},
                {"CHF", "Swiss Franc"},
                {"CNY", "Chinese Yuan"},
                {"SEK", "Swedish Krona"},
                {"NZD", "New Zealand Dollar"},
                {"MXN", "Mexican Peso"},
                {"SGD", "Singapore Dollar"},
                {"HKD", "Hong Kong Dollar"},
                {"NOK", "Norwegian Krone"},
                {"ZAR", "South African Rand"},
                {"TRY", "Turkish Lira"},
                {"BRL", "Brazilian Real"},
                {"INR", "Indian Rupee"},
                {"RUB", "Russian Ruble"},
                {"KRW", "South Korean Won"},
                {"PLN", "Polish Zloty"},
                {"THB", "Thai Baht"},
                {"IDR", "Indonesian Rupiah"},
                {"HUF", "Hungarian Forint"},
                {"CZK", "Czech Republic Koruna"},
                {"ILS", "Israeli New Sheqel"},
                {"CLP", "Chilean Peso"},
                {"PHP", "Philippine Peso"},
                {"AED", "UAE Dirham"},
                {"COP", "Colombian Peso"},
                {"SAR", "Saudi Riyal"},
                {"MYR", "Malaysian Ringgit"},
                {"RON", "Romanian Leu"},
                {"BGN", "Bulgarian Lev"},
                {"HRK", "Croatian Kuna"},
                {"DKK", "Danish Krone"},
                {"ISK", "Icelandic Krona"}
            };
        }
    }

    public class ExchangeRateData
    {
        [JsonProperty("base")]
        public string Base { get; set; } = string.Empty;

        [JsonProperty("date")]
        public string Date { get; set; } = string.Empty;

        [JsonProperty("rates")]
        public Dictionary<string, decimal> Rates { get; set; } = new Dictionary<string, decimal>();
    }
}
