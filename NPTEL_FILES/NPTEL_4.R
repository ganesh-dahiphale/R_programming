x = matrix(nrow=4, ncol=3, data=c(1:12))
x

rownames(x) = c("r1", "r2", "r3", "r4")
x
colnames(x) = c("c1", "c2", "c3")
x

x = matrix(nrow=4, ncol=2, data=2)
x

d = diag(1, nrow=3, ncol=3)
d

d = diag(5, nrow=3, ncol=3)
d

x = matrix(nrow=5, ncol=3, byrow=T, data=1:15)
x

xt = t(x) 
xt

x = matrix(nrow=4, ncol=2, data=c(1,2,3,4,5,6,7,8))
x

rowSums(x)
colSums(x)

rowMeans(x)
colMeans(x)

x = matrix(nrow=5, ncol=3, byrow=T, data=1:15)
x

x[3,]

x[,2]

x[4:5, 2:3]

x[c(1,4), c(1,3)]

x = matrix(nrow=4, ncol=2, data=1:8, byrow=T)
x

x + 5

x - 5

5 * x

x / 2

x = matrix(nrow=4, ncol=2, data=1:8, byrow=T)
y = matrix(nrow=4, ncol=2, data=11:18, byrow=T)

x + y
x - y
4 * x - x

y2 = matrix(nrow=2, ncol=4, data=11:18, byrow=T)
x %*% y2
y2 %*% x

t(x)
t(x) %*% x
x %*% t(x)
crossprod(x)

x = matrix(nrow=3, ncol=2, data=1:6, byrow=T)
y = matrix(nrow=3, ncol=2, data=11:16, byrow=T)

rbind(x, y)
cbind(x, y)

y_square = matrix(nrow = 2, ncol = 2, byrow = T, data = c(84,100,100,120))
y_square
solve(y_square)
eigen(y_square)

x = 8
(x < 10) || (x < 2)
x = 18
(x < 10) || (x < 2)

x = 5
(x < 10) && (x > 2)
x = 15
(x < 10) && (x > 2)

x = c(8, 18)
(x < 10) || (x < 2) 
(x < 10) | (x < 2)  

(x < 10) && (x > 2)
(x < 10) & (x > 2)

x = 1:6
(x > 2) & (x < 5)
x[(x > 2) & (x < 5)]

(x > 2) | (x < 5)
x[(x > 2) | (x < 5)]

(x > 2) && (x < 5)

x = TRUE
y = FALSE
x & y
x | y
!x

x = 5
logical1 = (x > 2)
logical1
is.logical(logical1)

Logical2 = (x < 10)
Logical2
is.logical(Logical2)

Logical3 = (x != 5)
Logical3
is.logical(Logical3)

Logical4 = (2 * x > 11)
Logical4
is.logical(Logical4)

Logical5 = (3 * x < 20)
Logical5
is.logical(Logical5)

x = c(1, 2, 3)
y = c(4, 5, 6)
x > y
x < y

isTRUE(8 < 6)

