@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'interface cds for supply'
@Metadata.ignorePropagatedAnnotations: true

define view entity zi_red_supply
  as select from zred_supply_m

  association to parent ZI_RED_BOOK as _Booking
    on  $projection.BookingId = _Booking.BookingId
    and $projection.TravelId  = _Booking.TravelId

  association [1..1] to /DMO/I_Supplement as _Supplyment
    on $projection.SupplementId = _Supplyment.SupplementID

  association [1..*] to /DMO/I_SupplementText as _SupplymentText
    on $projection.SupplementId = _SupplymentText.SupplementID
    association [1..1] to zi_red_travel as _Travel on $projection.TravelId = _Travel.TravelId
{
  key travel_id             as TravelId,
  key booking_id            as BookingId,
  key booking_supplement_id as BookingSupplementId,

      supplement_id         as SupplementId,

      @Semantics.amount.currencyCode: 'CurrencyCode'
      price                 as Price,

      currency_code         as CurrencyCode,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      last_changed_at       as LastChangedAt,

      _Supplyment,
      _SupplymentText,
      _Booking,
      _Travel
}
