import happybase
print('happybase', happybase.__version__)
c = happybase.Connection('127.0.0.1', 9090, autoconnect=True)
print('tables:', sorted(c.tables()))
name = 'val_hb_py'
if name.encode() not in c.tables():
    c.create_table(name, {'fam': dict()})
t = c.table(name)
t.put(b'row1', {b'fam:col': b'hello-happybase'})
print('get row1:', t.row(b'row1'))
print('scan:', list(t.scan()))
if name.encode() in c.tables():
    c.disable_table(name)
    c.delete_table(name)
print('OK happybase roundtrip')