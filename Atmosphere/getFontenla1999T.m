function [S, P, A] = getFontenla1999T

S = [ ...
    471 614;...
    479 616;...
    491 618;...
    510 619;...
    592 619;...
    616 616;...
    635 611;...
    656 605;...
    675 599;...
    700 595;...
    740 592;...
    768 589;...
    776 587;...
    788 582;...
    796 578;...
    797 576;...
    798 517;...
    799 469;...
    800 455;...
    805 436;...
    809 425;...
    816 416;...
    823 410;...
    839 402;...
    858 396;...
    882 391;...
    918 386;...
    958 383;...
    1018 378;...
    1072 375;...
    1100 374 ...
    ];

P = [...
    471 594;...
    489 599;...
    512 602;...
    555 605;...
    580 606;...
    605 604;...
    627 601;...
    650 598;...
    677 595;...
    727 592;...
    768 589;...
    839 584;...
    861 582;...
    862 578;...
    863 470;...
    864 432;...
    866 416;...
    868 408;...
    875 398;...
    892 387;...
    911 381;...
    938 375;...
    975 370;...
    1029 365;...
    1072 363;...
    1100 361 ...
    ];

A = [ ...
    470 593;...
    484 599;...
    500 603;...
    542 608;...
    566 610;...
    588 612;...
    604 611;...
    620 608;...
    642 605;...
    655 601;...
    676 598;...
    715 594;...
    773 592;...
    846 590;...
    881 588;...
    908 588;...
    928 585;...
    947 581;...
    959 576;...
    962 573;...
    964 567;...
    965 507;...
    966 483;...
    970 458;...
    972 446;...
    976 436;...
    982 428;...
    990 422;...
    1002 416;...
    1024 410;...
    1049 404;...
    1069 402;...
    1100 399 ...
    ];

Sh0 = 471;
Sh2500 = 1033;
ST4 = 575;
ST6 = 378;

S(:, 1) = (S(:, 1)-Sh0)/(Sh2500-Sh0)*2500*1e5;
P(:, 1) = (P(:, 1)-Sh0)/(Sh2500-Sh0)*2500*1e5;
A(:, 1) = (A(:, 1)-Sh0)/(Sh2500-Sh0)*2500*1e5;
S(:, 2) = (S(:, 2)-ST4)/(ST6-ST4)*2 + 4;
P(:, 2) = (P(:, 2)-ST4)/(ST6-ST4)*2 + 4;
A(:, 2) = (A(:, 2)-ST4)/(ST6-ST4)*2 + 4;

end
