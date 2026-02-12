%let selection = RANDOM;   /* FIRST ou RANDOM */
%let N = 20;
%let seed = 12345;

%let selection = %upcase(%superq(selection));

/* Validação */
%if not (&selection = FIRST or &selection = RANDOM) %then %do;
  %put ERROR: SELECTION deve ser FIRST ou RANDOM. Valor atual=&selection;
  %abort cancel;
%end;

/* FIRST: ObsNum sequencial (1..N) */
%if &selection = FIRST %then %do;

  title1 color="#545B66" "Sample from SASHELP.HOMEEQUITY";
  title2 height=3 "First &N Rows (ObsNum is sequential)";

  data sample;
    retain ObsNum;
    set sashelp.homeequity(obs=&N keep=Bad Loan MortDue Value);
    ObsNum = _N_;
  run;

%end;

/* RANDOM: ObsNum aleatório (número da obs original) */
%if &selection = RANDOM %then %do;

  title1 color="#545B66" "Sample from SASHELP.HOMEEQUITY";
  title2 height=3 "Random &N Rows (ObsNum is original row number)";

  /* 1) Cria uma “tabela índice” com o número real da observação */
  data _home_idx;
    set sashelp.homeequity(keep=Bad Loan MortDue Value);
    ObsNum = _N_;
  run;

  /* 2) Sorteia N valores de ObsNum */
  proc surveyselect data=_home_idx(keep=ObsNum)
    out=_idx
    method=srs
    sampsize=&N
    seed=&seed
    noprint;
  run;

  /* 3) Junta para trazer as variáveis do dataset original */
  proc sql;
    create table sample as
    select i.ObsNum,
           h.Bad,
           h.Loan,
           h.MortDue,
           h.Value
    from _idx i
    inner join _home_idx h
      on i.ObsNum = h.ObsNum
    order by i.ObsNum;   /* opcional: ordena pelo número original */
  quit;

%end;

/* PRINT */
footnote height=3 "Created %sysfunc(today(),nldatew.) at %sysfunc(time(), nltime.)";
proc print data=sample noobs;
run;

title;
footnote;
