@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'projection view for travel app'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
@Search.searchable: true
define view entity zc_booking_projection as projection on ZI_RED_BOOK 

{
    key TravelId,
    
    
    key BookingId,
    
    BookingDate,
    
    CustomerId,
    CarrierId,
    ConnectionId,
    FlightDate,
    @Semantics.amount.currencyCode: 'CurrencyCode'
    FlightPrice,
    CurrencyCode,
    @ObjectModel.text.element: [ 'BookingStatusText' ]
    
    BookingStatus,
    _BookingStatus._Text.Text as BookingStatusText : localized,
    LastChangedAt,
    /* Associations */
    _BookingStatus,
    _Carrier,
    _Connection,
    _Currency,
    _Customer,
    _supply: redirected to composition child zc_supply_projection,
    _Travel : redirected to parent zc_red_travel,
    _Customer.FirstName as FirstName
}
