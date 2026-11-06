kind = { 'Brian':'badger', 'Conor':'cat', 'Dara':'dog', 'Fiona':'dog',
         'Ronan':'mouse', 'Seamus':'cat', 'Tara':'mouse' }
animals = list(kind)

swim   = { 'Brian', 'Fiona' }
sleep  = { 'Seamus' }

chase  = { ('Dara','Fiona'), ('Fiona','Conor'), ('Conor','Tara'), ('Seamus','Ronan') }
fear   = { ('Tara','Conor'), ('Tara','Seamus'), ('Ronan','Brian'),
           ('Conor','Fiona'), ('Seamus','Dara'), ('Fiona','Dara'),
           ('Brian','Fiona') }

hungry = { 'Conor', 'Dara', 'Ronan' }
grey   = { 'Seamus', 'Tara' }


def names(xs): 
    return ", ".join(xs) if xs else 'nobody'

def yes_no(b):
    return 'yes' if b else 'no'