**free
ctl-opt bnddir('CLV1/CUSTOMERS');

dcl-f test21 workstn
    extdesc('CLV1/TEST21')
    extfile(*extdesc)
    sfile(sfldet01:nrr01);

// TEST21 
// This program shows how to use a simple SFL
// - It uses procedures of service programs.
// - No files declared.
// - No SQL instruction used.

// My "includes"
/include "/home/CLV/customers/qrpglesrc/customers_h.rpgle"
/include "/home/CLV/orders/qrpglesrc/orders_h.rpgle"

dcl-c #OK 'S';
dcl-s #exit01 char(1);
dcl-s #exit02w char(1);
dcl-s #exit03w char(1);
dcl-s #lastnrr01 zoned(4);
dcl-s #nbr01 zoned(4);
dcl-s #a zoned(4);
dcl-ds #customer likeds(customer_t);

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
            #customer = Customers_FetchNext();
            if (not Customers_isOk());
                leave;
            endif;
            // I move the data retrieve from the cursor to the subfile fields
            wsid = #customer.id;
            wsdescrip = #customer.descrip;
            wsorders = getNumofCustomerOrders(#customer.id);

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
            when (*inkc);
                // F3=End Program
                exsr endpgm;
            when (*inke);
                // F5=Update
                #exit01 = #OK;
            other;
                // Enter
                if (nrr01 > 0 and wscursor01 > 0);
                    #nbr01 = wscursor01;
                else;
                    #nbr01 = 1;
                endif;
                if (nrr01 > 0);
                    exsr select01;
                endif;
        endsl;
    enddo;
endsr;

// ****************************************************************************
// Subroutine Select01 -
// ****************************************************************************
begsr select01;

    for #a = 1 to #lastnrr01;
        chain #a SFLDET01;
        if (%found and wsoption01 <> 0);
            select;
                when (wsoption01 = 4);
                    // 4=Delete
                    // Trying to delete a customer
                    if (deleteCustomer(wsid));
                        // If success, shows message.
                        exsr show02w;
                    else;
                        // If not, shows error message.
                        exsr show03w;
                    endif;
                    
                when (wsoption01 = 5);
                    // 5=View
                    // TO-DO
            endsl;
            wsoption01 = 0;
            #nbr01 = #a;
            update SFLDET01;
        endif;
    endfor;

endsr;

// ****************************************************************************
// Subroutine Show02w - Shows window 02.
// ****************************************************************************
begsr show02w;
    
    #exit02w = *blanks;
    dou (#exit02w = #OK);

        exfmt WINDOW02;

        select;
            when (*inkc);
                // F3=End Program
                exsr endpgm;
            when (*inkl);
                // F12=Back
                #exit02w = #OK;
                #exit01 = #OK;
        endsl;
    enddo;
endsr;

// ****************************************************************************
// Subroutine Show03w - Shows window 03.
// ****************************************************************************
begsr show03w;
    
    #exit03w = *blanks;
    dou (#exit03w = #OK);

        exfmt WINDOW03;

        select;
            when (*inkc);
                // F3=End Program
                exsr endpgm;
            when (*inkl);
                // F12=Back
                #exit03w = #OK;
                #exit01 = #OK;
        endsl;
    enddo;
endsr;

// ****************************************************************************
// Subroutine endpgm - Ends program.
// ****************************************************************************
begsr endpgm;
    *inlr = '1';
    return;
endsr;

// ****************************************************************************
// Subroutine *inzsr 
// ****************************************************************************
begsr *inzsr;
endsr;
