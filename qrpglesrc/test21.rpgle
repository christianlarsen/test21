**free
ctl-opt bnddir('CLV1/CUSTOMERS');

dcl-f test21 workstn
    extdesc('CLV1/TEST21')
    extfile(*extdesc)
    sfile(sfldet01:nrr01)
    indds(#wsind);

// TEST21 
// This program shows how to use a simple SFL
// - It uses procedures of service programs.
// - No files declared.
// - No SQL instruction used.

// My "includes"
/include "/home/CLV/customers/qrpglesrc/customers_h.rpgle"

// Structure for the display indicadors
dcl-ds #wsind qualified;
    endOfPgm ind pos(3);
    updateDsp ind pos(5);
    back ind pos(12);
    clearSfl ind pos(80);
end-ds;
// Constants
dcl-c #OK 'S';

// Main

// doTests();

// Process subfile 01
// - Initialize + Fill + Show data
processSubfile01();

// - Ends Program
endPgm();

///
// doTests
// Subprocedure just for testing
///
dcl-proc doTests;

    dcl-pi doTests;
    end-pi;
    
    dcl-ds #customerList likeds(customerList_t) inz(*likeds);
    dcl-s #customerListJSON varchar(2000000) inz;

    // Tests
    #customerList = getCustomerlist();
    #customerListJSON = getCustomerListJSON();
    #customerList = getCustomerListFromJSON(#customerListJSON);

    return;

end-proc;

///
// processSubfile01
// Subprocedure that processes subfile01.
///
dcl-proc processSubfile01;

    dcl-pi processSubfile01;
    end-pi;

    dcl-s #a zoned(4);
    dcl-s #exit char(1);
    dcl-s #exit01 char(1);
    dcl-s #lastnrr01 zoned(4);
    dcl-s #nbr01 zoned(4);
    dcl-ds #customer likeds(customer_orders_t) inz(*likeds);

    // Loop until #exit is "OK"
    #exit = *blanks;
    dou (#exit = #OK);
        exsr init;
        exsr fill;
        exsr show;
    enddo;

    return;

    // Initializes subfile01
    begsr init;
        #wsind.clearSfl = *ON;
        write SFLHEA01;
        #wsind.clearSfl = *OFF;
        nrr01 = 0;
        nbr01 = 1;
        // Inicializa subtotales
        wstorders = 0;
    endsr;

    // Fills subfile01
    begsr fill;
        // I open the cursor
        if (Customers_Orders_Open());

            // Do this while Customers_isOk is "1"    
            dou (not Customers_isOk());

                // I fetch data from the cursor
                #customer = Customers_Orders_FetchNext();
                if (not Customers_isOk());
                    leave;
                endif;
                // I move the data retrieve from the cursor to the subfile fields
                wsid = #customer.id;
                wsdescrip = #customer.descrip;
                // wsorders = getNumofCustomerOrders(#customer.id);
                wsorders = #customer.orders;

                // Add to subtotals
                wstorders += wsorders;
                // Add record to subfile
                nrr01 += 1;
                write SFLDET01;            

            enddo;

            Customers_Orders_Close();

        endif;

        // Saves last record number
        #lastnrr01 = nrr01;
        wslstnrr01 = nrr01;
    endsr;

    // Shows subfile01
    begsr show;
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
                when (#wsind.endOfPgm);
                    // F3=End Program
                    return;
                when (#wsind.updateDsp);
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
                        exsr processRecords;
                    endif;
            endsl;
        enddo;
    endsr;

    // Selection of records in subfile01
    begsr processRecords;
        for #a = 1 to #lastnrr01;
            chain #a SFLDET01;
            if (%found and wsoption01 <> 0);
                select;
                    when (wsoption01 = 4);
                        // 4=Delete
                        // Trying to delete a customer
                        if (deleteCustomer(wsid));
                            // If success, shows message.
                            processWindow02();
                        else;
                            // If not, shows error message.
                            processWindow03();
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

end-proc;

///
// processWindow02
// Subprocedure that processes window02.
///
dcl-proc processWindow02;

    dcl-pi processWindow02;
    end-pi;

    dcl-s #exit02w char(1);
    
    exsr show;

    return;

    begsr show;
        #exit02w = *blanks;
        dou (#exit02w = #OK);

            exfmt WINDOW02;

            select;
                when (#wsind.endOfPgm);
                    // F3=End Program
                    return;
                when (#wsind.back);
                    // F12=Back
                    #exit02w = #OK;
            endsl;
        enddo;
    endsr;

end-proc;

///
// processWindow03
// Subprocedure that processes window03.
///
dcl-proc processWindow03;

    dcl-pi processWindow03; 
    end-pi;
    
    dcl-s #exit03w char(1);

    exsr show;

    return;

    begsr show;    
        #exit03w = *blanks;
        dou (#exit03w = #OK);

            exfmt WINDOW03;

            select;
                when (#wsind.endOfPgm);
                    // F3=End Program
                    return;
                when (#wsind.back);
                    // F12=Back
                    #exit03w = #OK;
            endsl;
        enddo;
    endsr;
end-proc;

///
// endpgm
// Ends program.
///
dcl-proc endPgm;
    dcl-pi endpgm;
    end-pi;

    *inlr = '1';
    return;
end-proc;
