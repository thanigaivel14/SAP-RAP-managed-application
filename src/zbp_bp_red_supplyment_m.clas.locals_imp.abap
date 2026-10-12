CLASS lhc_supplymenet DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS TotalPriceDT FOR DETERMINE ON MODIFY
       keys FOR Supplymenet~TotalPriceDT.

ENDCLASS.

CLASS lhc_supplymenet IMPLEMENTATION.

  METHOD TotalPriceDT.
  DATA: lt_travel TYPE TABLE OF zi_red_travel WITH UNIQUE HASHED KEY key COMPONENTS TravelId.
  LOOP AT keys ASSIGNING FIELD-SYMBOL(<fs_key>).
INSERT VALUE #(
  TravelId = <fs_key>-TravelId
) INTO TABLE lt_travel.
  ENDLOOP.
    MODIFY ENTITIES OF zi_red_travel IN LOCAL MODE
   ENTITY Travel
   EXECUTE  recalTotalPrice
   FROM CORRESPONDING #( lt_travel ).
  ENDMETHOD.

ENDCLASS.

*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations

