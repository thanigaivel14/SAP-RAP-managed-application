CLASS lsc_zi_red_travel DEFINITION INHERITING FROM cl_abap_behavior_saver.

  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

ENDCLASS.

CLASS lsc_zi_red_travel IMPLEMENTATION.

  METHOD save_modified.


    IF create-travel IS NOT INITIAL.

    ENDIF.
    IF update-travel IS NOT INITIAL.
      DATA lt_travel_log TYPE STANDARD TABLE OF zlog_travel_01.
      DATA lt_travel_log_result TYPE STANDARD TABLE OF zlog_travel_01.
      lt_travel_log = CORRESPONDING #( update-travel  ).

      LOOP AT lt_travel_log ASSIGNING FIELD-SYMBOL(<fs_travel_log>).
        <fs_travel_log>-change_operation = 'create'.
        GET TIME STAMP FIELD <fs_travel_log>-change_at.

        READ TABLE update-travel   ASSIGNING FIELD-SYMBOL(<fs_create>) WITH TABLE KEY entity COMPONENTS
         TravelId = <fs_travel_log>-travelid.

        IF sy-subrc IS INITIAL.

          TRY.
              <fs_travel_log>-log_id = cl_system_uuid=>create_uuid_x16_static(  ).
            CATCH cx_uuid_error.
              "handle exception
          ENDTRY.

          IF <fs_create>-%control-TotalPrice = cl_abap_behv=>flag_changed.
            <fs_travel_log>-chage_field = 'Total Price'.
            <fs_travel_log>-change_value = <fs_create>-TotalPrice.
            APPEND <fs_travel_log> TO lt_travel_log_result.
          ENDIF.

        ENDIF.

      ENDLOOP.
      INSERT zlog_travel_01 FROM TABLE  @lt_travel_log_result.
    ENDIF.
    IF delete-travel IS NOT INITIAL.
    ENDIF.


********************************************************************************

*    DATA lt_book_supp TYPE STANDARD TABLE OF  zred_supply_m.
*
*    IF create-supplymenet IS NOT INITIAL.
*
*      lt_book_supp = VALUE #( FOR supply IN create-supplymenet (
*      travel_id = supply-TravelId
*      booking_id = supply-BookingId
*      booking_supplement_id = supply-BookingSupplementId
*      currency_code = supply-CurrencyCode
*      last_changed_at = supply-LastChangedAt
*      supplement_id = supply-SupplementId
*
*          ) ).
*
*      INSERT zred_supply_m FROM TABLE @lt_book_supp.
*    ENDIF.
    .
  ENDMETHOD.

ENDCLASS.

CLASS lhc_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      keys REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      REQUEST requested_authorizations FOR Travel RESULT result.


    METHODS copyTravel FOR MODIFY
       keys FOR ACTION Travel~copyTravel.

    METHODS recalTotalPrice FOR MODIFY
       keys FOR ACTION Travel~recalTotalPrice.

    METHODS acceptTravel FOR MODIFY
       keys FOR ACTION Travel~acceptTravel RESULT result.

    METHODS rejectTravel FOR MODIFY
       keys FOR ACTION Travel~rejectTravel RESULT result.

    METHODS get_instance_features FOR INSTANCE FEATURES
      keys REQUEST requested_features FOR Travel RESULT result.

    METHODS validatecust FOR VALIDATE ON SAVE
       keys FOR travel~validatecust.

    METHODS validatebookdate FOR VALIDATE ON SAVE
       keys FOR travel~validatebookdate.

    METHODS totalpricedt FOR DETERMINE ON MODIFY
       keys FOR travel~totalpricedt.


    METHODS earlynumbering_cba_Booking FOR NUMBERING
       entities FOR CREATE Travel\_Booking.

    METHODS earlynumbering_create
      FOR NUMBERING
      IMPORTING entities FOR CREATE Travel.

ENDCLASS.

CLASS lhc_Travel IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD earlynumbering_create.
    DATA(lt_entites) = entities.
    DELETE lt_entites WHERE TravelId IS NOT INITIAL.
    TRY.
        cl_numberrange_runtime=>number_get(
          EXPORTING
*      ignore_buffer     =
            nr_range_nr       = '01'
            object            = '/DMO/TRV_M'
            quantity          = CONV #( lines(  lt_entites ) )
          IMPORTING
            number            = DATA(lv_lastest_num)
            returncode        = DATA(lv_code)
            returned_quantity = DATA(lv_qty)
        ).


      CATCH cx_nr_object_not_found.
      CATCH cx_number_ranges INTO DATA(lt_error).
        LOOP AT lt_entites INTO DATA(ls_entite).
          APPEND VALUE #( %cid = ls_entite-%cid
                           %key = ls_entite-%key )
                          TO failed-travel.
          APPEND VALUE #( %cid = ls_entite-%cid
                          %key = ls_entite-%key
                          %msg = lt_error ) TO reported-travel.



        ENDLOOP.
        EXIT.
    ENDTRY.
    ASSERT lv_qty = lines( lt_entites ) .
    DATA(lv_curr_num) =  CONV intad( lv_lastest_num - lv_qty ).
    DATA:lt_red_travel TYPE TABLE FOR MAPPED EARLY zi_red_travel,
         ls_red_travel LIKE  LINE OF lt_red_travel.
    LOOP AT lt_entites INTO DATA(ls_entites).
      lv_curr_num = lv_curr_num + 1.

      ls_red_travel = VALUE #(
      %cid = ls_entites-%cid
      TravelId = lv_curr_num
      ).
      APPEND ls_red_travel TO mapped-travel.
    ENDLOOP.
  ENDMETHOD.

  METHOD earlynumbering_cba_Booking.
    DATA: lv_max_num TYPE /dmo/booking_id.
    READ ENTITIES OF zi_red_travel IN LOCAL MODE
    ENTITY Travel BY \_Booking
    FROM CORRESPONDING #(   entities )
    LINK DATA(lt_link_data).
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<ls_group_entites>) GROUP BY <ls_group_entites>-TravelId.
      lv_max_num = REDUCE #(  INIT lv_max = CONV /dmo/booking_id( '0' )
                              FOR ls_link IN lt_link_data
                              USING KEY entity
                              WHERE ( source-TravelId = <ls_group_entites>-TravelId )
                              NEXT lv_max = COND /dmo/travel_id( WHEN lv_max < ls_link-target-BookingId
                                                                       THEN ls_link-target-BookingId
                                                                       ELSE lv_max ) ).
      lv_max_num = REDUCE #( INIT lv_max = lv_max_num
                             FOR ls_entites IN entities
                             USING KEY  entity
                             WHERE  ( TravelId = <ls_group_entites>-TravelId )
                             FOR ls_booking IN ls_entites-%target
                             NEXT lv_max = COND /dmo/travel_id( WHEN lv_max < ls_booking-BookingId
                                                                        THEN ls_booking-BookingId
                                                                        ELSE lv_max ) ).


      LOOP AT entities ASSIGNING FIELD-SYMBOL(<ls_entities>) USING KEY entity WHERE TravelId = <ls_group_entites>-TravelId.

        LOOP AT <ls_entities>-%target ASSIGNING FIELD-SYMBOL(<ls_booking>).
          APPEND CORRESPONDING #( <ls_booking> ) TO mapped-booking ASSIGNING FIELD-SYMBOL(<ls_new_booking>).
          lv_max_num += 1.
          IF <ls_booking>-BookingId IS INITIAL.

            <ls_new_booking>-BookingId = lv_max_num.
          ENDIF.
        ENDLOOP.

      ENDLOOP.

    ENDLOOP.

*//loop the screen and update the booking Id


  ENDMETHOD.



  METHOD copyTravel.

    DATA: lt_travel  TYPE TABLE FOR CREATE zi_red_travel,
          lt_booking TYPE TABLE FOR CREATE zi_red_travel\_Booking,
          lt_supply  TYPE TABLE FOR CREATE zi_red_book\_supply.

    READ TABLE keys ASSIGNING FIELD-SYMBOL(<ls_without_cid>) WITH KEY %cid = ' '.
    ASSERT <ls_without_cid> IS NOT ASSIGNED.

    READ ENTITIES OF  zi_red_travel IN LOCAL MODE
    ENTITY Travel
    ALL FIELDS WITH  CORRESPONDING #( keys )
    RESULT  DATA(lt_travel_result)
    FAILED DATA(lt_travel_failed).

    READ ENTITIES OF zi_red_travel IN LOCAL MODE
    ENTITY travel BY \_Booking
    ALL FIELDS WITH CORRESPONDING #( lt_travel_result )
    RESULT DATA(lt_book_result).

    READ ENTITIES OF zi_red_travel IN LOCAL MODE
    ENTITY Booking BY \_supply
    ALL FIELDS WITH CORRESPONDING #( lt_book_result )
    RESULT DATA(lt_supply_result).

    LOOP AT lt_travel_result ASSIGNING  FIELD-SYMBOL(<lt_travel>).

      APPEND INITIAL LINE TO lt_travel ASSIGNING FIELD-SYMBOL(<ls_travel>).
      <ls_travel>-%cid = keys[ KEY entity  TravelId = <lt_travel>-TravelId ]-%cid.
**<ls_travel>-%data-AgencyId =  <lt_travel>-AgencyId.
      <ls_travel>-%data = CORRESPONDING #( <lt_travel> EXCEPT TravelId ).
      <ls_travel>-BeginDate = cl_abap_context_info=>get_system_date(  ).
      <ls_travel>-EndDate = cl_abap_context_info=>get_system_date(  ) + 30.
      <ls_travel>-OverallStatus = 'O'.


      APPEND VALUE #( %cid_ref = <ls_travel>-%cid

                       ) TO lt_booking ASSIGNING FIELD-SYMBOL(<fs_booking>).
      IF lt_booking IS NOT INITIAL.
        LOOP AT lt_book_result ASSIGNING FIELD-SYMBOL(<fs_result>) USING KEY entity   WHERE  TravelId = <lt_travel>-TravelId .
          APPEND VALUE #( %cid = <ls_travel>-%cid &&   <fs_result>-BookingId
                          %data = CORRESPONDING #( <fs_result> EXCEPT TravelId ) ) TO <fs_booking>-%target ASSIGNING FIELD-SYMBOL(<fs_new_book>).
          <fs_new_book>-BookingStatus = 'O'.

          IF lt_supply_result  IS NOT INITIAL.

            APPEND  VALUE #( %cid_ref = <fs_new_book>-%cid  ) TO lt_supply ASSIGNING FIELD-SYMBOL(<fs_book_supply>).

            LOOP AT lt_supply_result USING KEY entity ASSIGNING FIELD-SYMBOL(<ls_supply>) WHERE BookingId  = <fs_result>-BookingId  AND TravelId =  <lt_travel>-TravelId.
              APPEND  VALUE #( %cid = <fs_result>-BookingId && <lt_travel>-TravelId  && <ls_supply>-BookingSupplementId
                         %data = CORRESPONDING #( <ls_supply> EXCEPT TravelId BookingId ) ) TO <fs_book_supply>-%target.
            ENDLOOP.
          ENDIF.
        ENDLOOP.
      ENDIF.
    ENDLOOP.


    MODIFY ENTITIES OF zi_red_travel IN LOCAL MODE
        ENTITY Travel
        CREATE FIELDS ( AgencyId CustomerId BeginDate EndDate BookingFee TotalPrice CurrencyCode OverallStatus Description )
        WITH lt_travel
        ENTITY Travel
         CREATE BY \_Booking
         FIELDS ( BookingId BookingDate CustomerId CarrierId ConnectionId FlightDate FlightPrice CurrencyCode BookingStatus )
         WITH lt_booking
        ENTITY Booking
         CREATE BY \_supply
         FIELDS ( BookingSupplementId SupplementId Price CurrencyCode )
         WITH lt_supply
         MAPPED DATA(lt_map).

    mapped-travel = lt_map-travel.
    mapped-booking = lt_map-booking.
    mapped-supplymenet = lt_map-supplymenet.




  ENDMETHOD.




  METHOD recalTotalPrice.
    DATA : lt_travel_updated TYPE TABLE FOR  UPDATE zi_red_travel.
    TYPES : BEGIN OF ty_total,price TYPE /dmo/total_price ,
              curr_code TYPE /dmo/currency_code,
            END OF ty_total.
    DATA: lt_total TYPE TABLE OF ty_total.
    DATA updated_total TYPE /dmo/total_price.
    " Get Bookings of the selected Travel
    READ ENTITY IN LOCAL MODE zi_red_travel
    ALL FIELDS WITH
    CORRESPONDING #( keys )
    RESULT DATA(lt_travel).

    READ ENTITIES OF zi_red_travel IN LOCAL MODE
      ENTITY Travel
        BY \_Booking
        ALL FIELDS
          WITH CORRESPONDING #( lt_travel )
          RESULT DATA(lt_booking).

    READ ENTITIES OF zi_red_travel IN LOCAL MODE
    ENTITY Booking
      BY \_supply
      ALL FIELDS
        WITH CORRESPONDING #( lt_booking )
        RESULT DATA(lt_supply)
        FAILED DATA(lt_supply_failed).
    IF lt_supply_failed IS NOT INITIAL.
      EXIT.
    ENDIF.
    LOOP AT lt_travel ASSIGNING FIELD-SYMBOL(<fs_travel>).

      lt_total =  VALUE #( ( price = <fs_travel>-BookingFee curr_code = <fs_travel>-CurrencyCode ) ).

      LOOP AT lt_booking  ASSIGNING FIELD-SYMBOL(<fs_book>) USING KEY entity WHERE TravelId = <fs_travel>-TravelId.
        APPEND VALUE #( price = <fs_book>-FlightPrice curr_code = <fs_book>-CurrencyCode ) TO lt_total.

        LOOP AT lt_supply ASSIGNING FIELD-SYMBOL(<fs_supply>)
        USING KEY entity WHERE TravelId = <fs_book>-TravelId AND BookingId = <fs_book>-BookingId AND CurrencyCode IS NOT INITIAL.
          APPEND VALUE #(  price = <fs_supply>-Price curr_code = <fs_supply>-CurrencyCode  ) TO lt_total.
        ENDLOOP.
      ENDLOOP.

      LOOP AT lt_total ASSIGNING FIELD-SYMBOL(<fs_total>).

        IF <fs_total>-curr_code <> <fs_travel>-CurrencyCode.
          /dmo/cl_flight_amdp=>convert_currency(
                  EXPORTING
                    iv_amount               = <fs_total>-price
                    iv_currency_code_source = <fs_total>-curr_code
                    iv_currency_code_target = <fs_travel>-CurrencyCode
                    iv_exchange_rate_date   = cl_abap_context_info=>get_system_date(  )
                  IMPORTING
                    ev_amount               = <fs_travel>-TotalPrice
                ).
        ENDIF.
      ENDLOOP.
      LOOP AT lt_total ASSIGNING FIELD-SYMBOL(<fs_total_update>).
        updated_total += <fs_total_update>-price.
      ENDLOOP.

      <fs_travel>-TotalPrice = updated_total.



    ENDLOOP.

    MODIFY ENTITIES OF zi_red_travel IN LOCAL MODE
ENTITY travel
UPDATE
FIELDS ( TotalPrice )
WITH CORRESPONDING #( lt_travel ).

  ENDMETHOD.



  METHOD acceptTravel.
    MODIFY ENTITIES OF zi_red_travel IN LOCAL MODE
    ENTITY Travel
    UPDATE FIELDS ( OverallStatus )
    WITH VALUE #( FOR ls_key IN keys ( %tky = ls_key-%tky  OverallStatus = 'A' ) )
    REPORTED DATA(lt_travel).

    READ ENTITIES OF zi_red_travel  IN LOCAL MODE
    ENTITY Travel
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_result).

    result = VALUE #( FOR ls_result IN lt_result ( %tky = ls_result-%tky %param = ls_result ) ).

  ENDMETHOD.

  METHOD rejectTravel.

    MODIFY ENTITIES OF zi_red_travel IN LOCAL MODE
    ENTITY Travel
    UPDATE FIELDS ( OverallStatus )
    WITH VALUE #( FOR ls_key IN keys ( %tky = ls_key-%tky OverallStatus = 'X' ) )
    REPORTED DATA(lt_report).


    READ ENTITIES OF zi_red_travel IN LOCAL MODE
  ENTITY Travel
  ALL FIELDS WITH CORRESPONDING #( keys )
  RESULT DATA(lt_result).

    result = VALUE #( FOR ls_result IN lt_result ( %tky = ls_result-%tky %param = ls_result ) ).
  ENDMETHOD.

  METHOD get_instance_features.
    READ ENTITIES OF zi_red_travel IN LOCAL MODE
    ENTITY Travel  FIELDS ( TravelId   OverallStatus ) WITH CORRESPONDING #(  keys )
    RESULT DATA(lt_travel).

    result = VALUE #( FOR ls_travel IN lt_travel ( %tky = ls_travel-%tky
                                                  %features-%action-acceptTravel = COND #( WHEN ls_travel-OverallStatus = 'A'
                                                                                           THEN if_abap_behv=>fc-o-disabled
                                                                                           ELSE if_abap_behv=>fc-o-enabled )
                                                   %features-%action-rejectTravel = COND #( WHEN ls_travel-OverallStatus = 'X'
                                                                                           THEN if_abap_behv=>fc-o-disabled
                                                                                           ELSE if_abap_behv=>fc-o-enabled )
                                                   %features-%assoc-_Booking = COND #( WHEN ls_travel-OverallStatus = 'X'
                                                                                           THEN if_abap_behv=>fc-o-disabled
                                                                                           ELSE if_abap_behv=>fc-o-enabled )

    ) ).

  ENDMETHOD.

  METHOD validateCust.
    READ ENTITY IN LOCAL MODE zi_red_travel
    FIELDS ( CustomerId )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travel).

    DATA : lt_customer TYPE SORTED TABLE OF /dmo/customer WITH UNIQUE KEY customer_id .

    lt_customer = CORRESPONDING #( lt_travel DISCARDING DUPLICATES MAPPING customer_id = CustomerId ).

    DELETE lt_customer WHERE customer_id IS INITIAL.

    SELECT
    FROM /dmo/customer
    FIELDS customer_id
    FOR ALL ENTRIES IN @lt_customer
    WHERE customer_id =  @lt_customer-customer_id
    INTO TABLE @DATA(cust_db).

    LOOP AT lt_travel ASSIGNING FIELD-SYMBOL(<fs_travel>).

      IF <fs_travel>-CustomerId IS INITIAL OR NOT line_exists( cust_db[ customer_id = <fs_travel>-CustomerId ] ).
        APPEND VALUE #( %tky = <fs_travel>-%tky  ) TO  failed-travel.
      ENDIF.
    ENDLOOP.



  ENDMETHOD.

  METHOD validateBookdate.
    READ ENTITY IN LOCAL MODE zi_red_travel
    FIELDS ( BeginDate )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travel).
    DATA(lv_system_date) = cl_abap_context_info=>get_system_date( ).
    LOOP AT lt_travel ASSIGNING FIELD-SYMBOL(<fs_travel>).
      IF ( <fs_travel>-BeginDate < lv_system_date ).
        APPEND VALUE #( %tky = <fs_travel>-%tky ) TO failed-travel.
        APPEND VALUE #( %tky = <fs_travel>-%tky
                       %msg = NEW /dmo/cm_flight_messages(
          textid                =  /dmo/cm_flight_messages=>begin_date_on_or_bef_sysdate
          travel_id             = <fs_travel>-TravelId
          begin_date            = <fs_travel>-BeginDate
          severity              = if_abap_behv_message=>severity-error

        )
                       %element-BeginDate = if_abap_behv=>mk-on

                        ) TO reported-travel.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD TotalPriceDT.

    MODIFY ENTITIES OF zi_red_travel IN LOCAL MODE
    ENTITY Travel
    EXECUTE recalTotalPrice
    FROM CORRESPONDING #( keys ).
  ENDMETHOD.

ENDCLASS.
