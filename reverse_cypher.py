message = 'This is program to explain reverse cipher.'
translated = ''
length = len(message)
for i in range(length - 1) :
    translated += message[length - i - 1]
translated += message[0]
print "Cipher: " + translated