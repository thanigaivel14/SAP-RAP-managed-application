@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'projection view for travel app'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define view entity zc_supply_projection as projection on zi_red_supply
{
    key TravelId,
    key BookingId,
    key BookingSupplementId,
    SupplementId,
    @Semantics.amount.currencyCode: 'CurrencyCode'
    Price,
    CurrencyCode,
    LastChangedAt,
    /* Associations */
    _Booking: redirected to parent zc_booking_projection,
    _Supplyment, 
    _SupplymentText,
    _Travel: redirected to zc_red_travel
}
