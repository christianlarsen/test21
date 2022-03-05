**free
ctl-opt bnddir('CLV1/CUSTOMERS');

dcl-f test21 workstn
    extdesc('CLV1/TEST21')
    extfile(*extdesc)
    sfile(sfldet01:nrr01);

/include "/home/CLV/customers/qrpglesrc/customers_h.rpgle"
/include "/home/CLV/orders/qrpglesrc/orders_h.rpgle"


// TEST21 
// This program shows how to use a simple SFL with SQL

dcl-c #OK 'S';
dcl-s #exit01 char(1);
dcl-s #lastnrr01 zoned(4);
dcl-s #nbr01 zoned(4);
dcl-ds currentCustomer likeds(customer_t);

// Main

exsr init01;
exsr fill01;
exsr show01;

// ****************************************************************************
// Subroutine Init01 - Inicializes sfl 01.
// ****************************************************************************
begsr init01;
    *in80 = '1';
    write SFLHEA01;
    *in80 = '0';
    nrr01 = 0;
    nbr01 = 1;
    // Inicializa subtotales
    wstorders = 0;
endsr;

// ****************************************************************************
// Subroutine Fill01 - Fills sfl 01 with data.
// ****************************************************************************
begsr fill01;

    // I open the cursor
    if (Customers_Open());

        // Do this while Customers_isOk is "1"    
        dou (not Customers_isOk());

            // I fetch data from the cursor
            currentCustomer = Customers_FetchNext();
            if (not Customers_isOk());
                leave;
            endif;
            // I move the data retrieve from the cursor to the subfile fields
            wsid = currentCustomer.id;
            wsdescrip = currentCustomer.descrip;
            wsorders = getNumofCustomerOrders(currentCustomer.id);

            // Add to subtotals
            wstorders += wsorders;
            // Add record to subfile
            nrr01 += 1;
            write SFLDET01;            

        enddo;

        Customers_Close();

    endif;

    // Saves last record number
    #lastnrr01 = nrr01;
    wslstnrr01 = nrr01;
endsr;

// ****************************************************************************
// Subroutine Show01 - Shows sfl 01.
// ****************************************************************************
begsr show01;
    
    #exit01 = *blanks;
    dou (#exit01 = #OK);
        if (#nbr01 > 0 and #nbr01 <= #lastnrr01);
            nbr01 = #nbr01;
        endif;
        #nbr01 = 0;

        if (nrr01 > 0);
            write FOOTER01;
            exfmt SFLHEA01;
        else;
            exfmt DATA01;
        endif;

        select;
        // F3=End
        when (*inkc);
            exsr endpgm;
        // F5=Update
        when (*inke);
            #exit01 = #OK;
        // Intro
        other;
            if (nrr01 > 0 and wscursor01 > 0);
                #nbr01 = wscursor01;
            else;
                #nbr01 = 1;
            endif;
            // Selected records
            if (nrr01 > 0);
            //    exsr select01;
            endif;
        endsl;
    enddo;
endsr;

// ****************************************************************************
// Subroutine endpgm - Ends program.
// ****************************************************************************
begsr endpgm;

    // ??? Test!
    //deleteCustomer(5);
    
    *inlr = '1';
    return;
endsr;

// ****************************************************************************
// Subroutine *inzsr 
// ****************************************************************************
begsr *inzsr;

    // ??? Test!
    //currentCustomer.id = 5;
    //currentCustomer.descrip = 'Customer FIVE';
    //currentCustomer.descri2 = 'Customer FIVE(2b)';
    //addCustomer(currentCustomer);

endsr;
