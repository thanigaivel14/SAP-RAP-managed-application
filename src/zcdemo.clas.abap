CLASS zcdemo DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcdemo IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.
  MODIFY ENTITY zi_red_travel CREATE from value #( ( %cid = 'cid1'
                                                      %data-TotalPrice = '123'
                                                     %control-TotalPrice = if_abap_behv=>mk-on ) )
 MAPPED final(lt_mapped)
 failed final(lt_failed)
 REPORTED final(lt_final).

if lt_failed is not INITIAL.
out->write( lt_failed ).
ELSE.
out->write( lt_mapped ).
ENDIF.
COMMIT ENTITIES.
  ENDMETHOD.

ENDCLASS.
