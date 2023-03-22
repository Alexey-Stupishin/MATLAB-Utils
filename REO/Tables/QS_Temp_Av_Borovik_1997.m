function T = QS_Temp_Av_Borovik_1997(f)

A = [ ...
      2.0 	 10.5 ; ...
      2.3 	 11.0 ; ...
      2.7 	 11.8 ; ... 
      3.2 	 12.7 ; ... 
      4.0 	 13.8 ; ... 
      8.2 	 24.1 ; ... 
     11.7 	 33.2 ; ... 
     20.7 	 78.3 ; ... 
     31.6 	171.3 ; ... 
    ];

T = interp1(30./A(:, 1)*1e9, A(:, 2), vecColumn(f))*1e3;

end