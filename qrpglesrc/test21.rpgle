**free
ctl-opt main(main) bnddir('CLV1/CUSTOMERS');

dcl-f test21 workstn
    extdesc('CLV1/TEST21')
    extfile(*extdesc)
    sfile(sfldet01:nrr01)
    indds(#wsind);

// TEST21 
// This program shows how to use a simple SFL
// - It works in a "new" activation group.
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


///
// main
// main subprocedure
///
dcl-proc main;

    dcl-s #exit char(1);
    dcl-s #lastnrr01 zoned(4);

    // Loop until #exit is "OK"
    #exit = *blanks;
    dou (#exit = #OK);
        init01();
        #lastnrr01 = fill01();
        if show01(#lastnrr01);
            #exit = #OK;
        endif;
    enddo;

end-proc;

///
// Init01
// Initializes subfile01
///
dcl-proc init01;

    #wsind.clearSfl = *ON;
    write SFLHEA01;
    #wsind.clearSfl = *OFF;
    nrr01 = 0;
    nbr01 = 1;
    // Inicializa subtotales
    wstorders = 0;

end-proc;

///
// fill01
// Fills subfile01
///
dcl-proc fill01;

    dcl-pi *n zoned(4);
    end-pi;

    dcl-ds #customer likeds(customer_orders_t) inz(*likeds);

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
            wsoption01 = 0;
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

    wslstnrr01 = nrr01;

    // Returns last nrr added to the sfl.
    return nrr01;
end-proc;

///
// show01
// Shows subfile01
///
dcl-proc show01;

    dcl-pi *n ind;
        #lastnrr01 zoned(4) const;
    end-pi;
    dcl-s #nbr01 zoned(4);

    dcl-s #exit01 char(1);

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
                return '1';
            when (#wsind.updateDsp);
                // F5=Update
                return '0';
            other;
                // Enter
                if (nrr01 > 0 and wscursor01 > 0);
                    #nbr01 = wscursor01;
                else;
                    #nbr01 = 1;
                endif;
                if (nrr01 > 0);
                    if processRecords01(#lastnrr01:#nbr01);
                        return '1';
                    endif;
                endif;
        endsl;
    enddo;

end-proc;

///
// processRecords01
// Selection of records in subfile01
///
dcl-proc processRecords01;

    dcl-pi *n ind;
        #lastnrr01 zoned(4) const;
        #nbr01 zoned(4);
    end-pi;

    dcl-s #a zoned(5);

    for #a = 1 to #lastnrr01;
        chain #a SFLDET01;
        if (%found and wsoption01 <> 0);
            select;
                when (wsoption01 = 4);
                    // 4=Delete
                    // Trying to delete a customer
                    if (deleteCustomer(wsid));
                        // If success, shows message.
                        if processWindow02();
                            return '1';
                        endif;
                    else;
                        // If not, shows error message.
                        if processWindow03();
                            return '1';
                        endif;
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

    return '0';
end-proc;

///
// processWindow02
// Subprocedure that processes window02.
///
dcl-proc processWindow02;

    dcl-pi processWindow02 ind;
    end-pi;

    if show02();
        return '1';
    endif;

    return '0';
end-proc;

///
// show02
// Shows window02
///
dcl-proc show02;

    dcl-pi *n ind;
    end-pi;

    dcl-s #exit02w char(1);

    #exit02w = *blanks;
    dou (#exit02w = #OK);

        exfmt WINDOW02;

        select;
            when (#wsind.endOfPgm);
                // F3=End Program
                return '1';
            when (#wsind.back);
                // F12=Back
                return '0';
        endsl;
    enddo;

end-proc;

///
// processWindow03
// Subprocedure that processes window03.
///
dcl-proc processWindow03;

    dcl-pi processWindow03 ind;
    end-pi;

    if show03();
        return '1';
    endif;

    return '0';
end-proc;

///
// show03
// Shows window03
///
dcl-proc show03;

    dcl-pi *n ind;
    end-pi;

    dcl-s #exit03w char(1);

    #exit03w = *blanks;
    dou (#exit03w = #OK);

        exfmt WINDOW03;

        select;
            when (#wsind.endOfPgm);
                // F3=End Program
                return '1';
            when (#wsind.back);
                // F12=Back
                return '0';
        endsl;
    enddo;

end-proc;