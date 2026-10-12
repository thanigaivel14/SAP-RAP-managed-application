CLASS lhc_booking DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS earlynumbering_cba_Supply FOR NUMBERING
       entities FOR CREATE Booking\_Supply.

    METHODS get_instance_features FOR INSTANCE FEATURES
      keys REQUEST requested_features FOR Booking RESULT result.
    METHODS totalpricedt FOR DETERMINE ON MODIFY
      keys FOR booking~totalpricedt.

ENDCLASS.

CLASS lhc_booking IMPLEMENTATION.

  METHOD earlynumbering_cba_Supply.
    DATA: supply_id TYPE /dmo/booking_supplement_id.
    READ ENTITIES OF zi_red_travel  IN LOCAL MODE
    ENTITY Booking BY \_supply
    FROM CORRESPONDING #( entities )
    LINK DATA(booking_supplement).

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<ls_group_entites>) GROUP BY <ls_group_entites>-%tky.

      supply_id = REDUCE #( INIT max = CONV /dmo/booking_supplement_id( '0' )
                            FOR bookingsupply IN booking_supplement
                             USING KEY entity
                             WHERE ( source-%tky = <ls_group_entites>-%tky )
                              NEXT max = COND /dmo/booking_supplement_id( WHEN  max < bookingsupply-target-BookingSupplementId
                                                                          THEN  bookingsupply-target-BookingSupplementId
                                                                          ELSE max  ) ).
      supply_id = REDUCE #( INIT new_max = supply_id
                            FOR ls_entities IN entities
                            USING KEY  entity
                            WHERE ( %tky = <ls_group_entites>-%tky )
                            FOR ls_supply IN ls_entities-%target
                            NEXT new_max =  COND /dmo/booking_supplement_id( WHEN  new_max < ls_supply-BookingSupplementId
                                                                          THEN  ls_supply-BookingSupplementId
                                                                          ELSE new_max  ) ).
      LOOP AT entities ASSIGNING FIELD-SYMBOL(<ls_entities>) USING KEY entity WHERE ( %tky = <ls_group_entites>-%tky ).

        LOOP AT <ls_entities>-%target ASSIGNING FIELD-SYMBOL(<ls_supply>).
         APPEND CORRESPONDING #( <ls_supply> ) TO mapped-supplymenet ASSIGNING FIELD-SYMBOL(<ls_new_supply>).
          supply_id += 1.
          IF <ls_supply>-BookingSupplementId IS INITIAL.

            <ls_new_supply>-BookingSupplementId = supply_id.
          ENDIF.
        ENDLOOP.

      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_instance_features.
  READ ENTITIES OF zi_red_travel IN LOCAL MODE
  ENTITY Booking
  FIELDS (   BookingStatus  )
  WITH CORRESPONDING #( keys )
  RESULT data(lt_booking).

  result = VALUE #( for ls_book in lt_booking ( %tky = ls_book-%tky %features-%assoc-_supply = cond #( WHEN ls_book-BookingStatus = 'X'
                                                                                                       then if_abap_behv=>fc-o-disabled
                                                                                                       ELSE if_abap_behv=>fc-o-enabled )
           ) ).

  ENDMETHOD.

  METHOD TotalPriceDT.
  MODIFY ENTITIES OF zi_red_travel IN LOCAL MODE
  ENTITY Travel
  EXECUTE  recalTotalPrice
  FROM CORRESPONDING #( keys ).
  ENDMETHOD.

ENDCLASS.

