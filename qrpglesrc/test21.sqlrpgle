**free

dcl-f test21 workstn
    extdesc('CLV1/TEST21')
    extfile(*extdesc)
    sfile(sfldet01:nrr01);

dcl-f customers usage(*input)
    extdesc('CLV1/CUSTOMERS')
    extfile(*extdesc)
    rename(customers:rcustomers)
    keyed prefix(c_);

dcl-f ordersl1 usage(*input)
    extdesc('CLV1/ORDERSL1')
    extfile(*extdesc)
    rename(orders:rordersl1)
    keyed prefix(o_);

// TEST21 
// This program shows how to use a simple SFL with SQL

dcl-c #OK 'S';
dcl-s #exit01 char(1);
dcl-s #lastnrr01 zoned(4);
dcl-s #nbr01 zoned(4);

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

    setll *loval rcustomers;
    dou (%eof(CUSTOMERS));
        read rcustomers;
        if (not %eof(CUSTOMERS));
            wsid = c_id;
            wsdescrip = c_descrip;
            // Let's count how many orders I have from every customer...
            wsorders = 0;
            setll c_id rordersl1;
            dou (%eof(ORDERSL1));
                reade c_id rordersl1;
                if (not %eof(ORDERSL1));
                    wsorders += 1;
                endif;
            enddo;
            wstorders += wsorders;
            // Add record to subfile
            nrr01 += 1;
            write SFLDET01;            
        endif;
    enddo;

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
    *inlr = '1';
    return;
endsr;

// ****************************************************************************
// Subroutine *inzsr 
// ****************************************************************************
begsr *inzsr;
endsr;
