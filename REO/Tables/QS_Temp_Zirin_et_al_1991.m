function T = QS_Temp_Zirin_et_al_1991(f)

A = [ ...
     18.0 	 10.3 ; ...
     16.4 	 10.7 ; ...
     14.8 	 10.8 ; ... 
     13.2 	 10.8 ; ... 
     11.8 	 11.0 ; ... 
     10.6 	 11.3 ; ... 
     9.4 	 12.2 ; ... 
     8.2 	 12.9 ; ... 
     7.0 	 14.1 ; ... 
     5.8 	 15.9 ; ... 
     5.0 	 17.6 ; ... 
     4.2 	 19.4 ; ... 
     3.6 	 21.7 ; ... 
     3.2 	 24.2 ; ...
     2.8 	 27.1 ; ...
     2.4 	 32.8 ; ...
     2.0 	 42.9 ; ...
     1.8 	 52.2 ; ...
     1.6 	 63.8 ; ...
     1.4 	 70.5 ; ...
    ];

T = interp1(A(:, 1)*1e9, A(:, 2), vecColumn(f))*1e3;

end
