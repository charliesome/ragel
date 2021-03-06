// -*-rust-*-
//
// Reverse Polish Notation Calculator
// Copyright (c) 2010 J.A. Roberts Tunney
// MIT License
//
// To compile:
//
//   ragel --host-lang=rust -o rpn.rs rpn.rl
//   rust -o rpn rpn.rs
//   ./rpn
//
// To show a diagram of your state machine:
//
//   ragel -V -p -o rpn.dot rpn.rl
//   dot -Tpng -o rpn.png rpn.dot
//   chrome rpn.png
//

%% machine rpn;
%% write data;

fn rpn(data: &str) -> Result<int, ~str> {
    let mut cs: int;
    let mut p = 0;
    let pe = data.len();
    let mut mark = 0;
    let mut st = ~[];

    %%{
        action mark { mark = p; }
        action push {
            let s = data.slice(mark, p);
            match from_str::<int>(s) {
              None => return Err(format!("invalid integer {}", s)),
              Some(i) => st.push(i),
            }
        }
        action add  { let y = st.pop().unwrap(); let x = st.pop().unwrap(); st.push(x + y); }
        action sub  { let y = st.pop().unwrap(); let x = st.pop().unwrap(); st.push(x - y); }
        action mul  { let y = st.pop().unwrap(); let x = st.pop().unwrap(); st.push(x * y); }
        action div  { let y = st.pop().unwrap(); let x = st.pop().unwrap(); st.push(x / y); }
        action abs  { let x = st.pop().unwrap(); st.push(x.abs());                 }
        action abba { st.push(666); }

        stuff  = digit+ >mark %push
               | '+' @add
               | '-' @sub
               | '*' @mul
               | '/' @div
               | 'abs' %abs
               | 'add' %add
               | 'abba' %abba
               ;

        main := ( space | stuff space )* ;

        write init;
        write exec;
    }%%

    if cs < rpn_first_final {
        if p == pe {
            Err(~"unexpected eof")
        } else {
            Err(format!("error at position {}", p))
        }
    } else if st.is_empty() {
        Err(~"rpn stack empty on result")
    } else {
        Ok(st.pop().unwrap())
    }
}

//////////////////////////////////////////////////////////////////////

#[test]
fn test_success() {
    let rpnTests = [
        (~"666\n", 666),
        (~"666 111\n", 111),
        (~"4 3 add\n", 7),
        (~"4 3 +\n", 7),
        (~"4 3 -\n", 1),
        (~"4 3 *\n", 12),
        (~"6 2 /\n", 3),
        (~"0 3 -\n", -3),
        (~"0 3 - abs\n", 3),
        (~" 2  2 + 3 - \n", 1),
        (~"10 7 3 2 * - +\n", 11),
        (~"abba abba add\n", 1332),
    ];

    for sx in rpnTests.iter() {
        match *sx {
            (ref s, x) => assert_eq!(rpn(*s).unwrap(), x),
        }
    }
}

#[test]
fn test_failure() {
    let rpnFailTests = [
        (~"\n", ~"rpn stack empty on result")
    ];

    for sx in rpnFailTests.iter() {
        match *sx {
            (ref s, ref x) => assert_eq!(&rpn(*s).unwrap_err(), x),
        }
    }
}
