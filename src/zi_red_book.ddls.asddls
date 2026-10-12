@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'interface cds for book'
@Metadata.ignorePropagatedAnnotations: true

define view entity ZI_RED_BOOK
  as select from zred_book_m

  composition [0..*] of zi_red_supply as _supply

  association to parent zi_red_travel as _Travel
    on $projection.TravelId = _Travel.TravelId

  association [1..1] to /DMO/I_Carrier as _Carrier
    on $projection.CarrierId = _Carrier.AirlineID

  association [1..1] to /DMO/I_Customer as _Customer
    on $projection.CustomerId = _Customer.CustomerID

  association [1..1] to I_Currency as _Currency
    on $projection.CurrencyCode = _Currency.Currency

  association [1..1] to /DMO/I_Connection as _Connection
    on  $projection.CarrierId    = _Connection.AirlineID
    and $projection.ConnectionId = _Connection.ConnectionID

  association [1..1] to /DMO/I_Booking_Status_VH as _BookingStatus
    on $projection.BookingStatus = _BookingStatus.BookingStatus

{
  key travel_id       as TravelId,
  key booking_id      as BookingId,

      booking_date    as BookingDate,
      customer_id     as CustomerId,
      carrier_id      as CarrierId,
      connection_id   as ConnectionId,
      flight_date     as FlightDate,

      @Semantics.amount.currencyCode: 'CurrencyCode'
      flight_price    as FlightPrice,

      currency_code   as CurrencyCode,
      booking_status  as BookingStatus,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      last_changed_at as LastChangedAt,

      _Carrier,
      _Customer,
      _Currency,
      _Connection,
      _BookingStatus,
      _Travel,
      _supply
}
