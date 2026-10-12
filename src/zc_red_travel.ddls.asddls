@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'consuption for travel'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define root view entity zc_red_travel
  provider contract transactional_query
  as projection on zi_red_travel
{
  key TravelId,
      @Search.defaultSearchElement: true
      @Consumption.valueHelpDefinition: [{ entity: {
          name: '/DMO/I_Agency',
          element: 'AgencyID'
      } }]
      AgencyId,
      _Agency.Name        as AgencyName,
      @ObjectModel.text.element: [ 'CustomerName' ]
      @Consumption.valueHelpDefinition: [{  entity:{
      element : 'CustomerID',
      name: '/DMO/I_Customer'
      } }]
      CustomerId,

      _Customer.FirstName as CustomerName,
      BeginDate,
      EndDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      BookingFee,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      TotalPrice,
        @Consumption.valueHelpDefinition: [{ entity: {
    name: 'I_Currency',
    element: 'Currency'
  } }]
      CurrencyCode,
      Description,
      @ObjectModel.text.element: [ 'overallText' ]
        @Consumption.valueHelpDefinition: [{ entity: {
   name: '/DMO/I_Overall_Status_VH',
   element: 'OverallStatus'
  } }]
      OverallStatus,
      _Status._Text.Text  as overallText : localized,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      /* Associations */
      _Agency,
      _Booking : redirected to composition child zc_booking_projection,
      _Currency,
      _Customer,
      _Status
}
