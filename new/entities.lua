#!/usr/bin/lua

local entities = {}

entities.is_function = function(f)
	if type(f)~='table' or string.find(f.label, 'Function')~=1 then
		return false
	else
		return true
	end
end
local is_function = entities.is_function


entities.is_constructor = function(f)
	assert(is_function(f), 'argument is not a function')
	return (f.xarg.member_of_class and f.xarg.member_of_class~=''
	and f.xarg.fullname==(f.xarg.member_of_class..'::'..f.xarg.name) -- this should be always true
	and string.match(f.xarg.member_of_class, f.xarg.name..'$')) and '[constructor]'
end
local is_constructor = entities.is_constructor

entities.is_destructor = function(f)
	assert(is_function(f), 'argument is not a function')
	return f.xarg.name:sub(1,1)=='~' and '[destructor]'
end
local is_destructor = entities.is_destructor

entities.takes_this_pointer = function(f)
	assert(is_function(f), 'argument is not a function')
	if f.xarg.member_of_class and not (f.xarg.static=='1') and f.xarg.member_of_class~=''
		and not is_constructor(f) then
		return f.xarg.member_of_class .. '*;'
	end
	return false
end
local takes_this_pointer = entities.takes_this_pointer 

entities.is_class = function(c)
	if type(c)=='table' and c.label=='Class' then
		return true
	else
		return false
	end
end
local is_class = entities.is_class

entities.class_is_copy_constructible = function(c)
	-- TODO: cache the response into the class itself (c.xarg.is_copy_constructible)
	assert(is_class(c), 'this is NOT a class')
	for _, m in ipairs(c) do
		if is_function(m)
			and is_constructor(m)
			and #m==1
			and m.xarg.access=='public'
			and (m[1].xarg.type_name==c.xarg.fullname..' const&'
			or m[1].xarg.type_name==c.xarg.fullname..'&'
			or m[1].xarg.type_name==c.xarg.fullname) then
			return true
		end
	end
	return false
end
local class_is_copy_constructible = entities.class_is_copy_constructible

entities.class_is_default_constructible = function(c)
	-- TODO: cache the response into the class itself (c.xarg.is_copy_constructible)
	assert(is_class(c), 'this is NOT a class')
	for _, m in ipairs(c) do
		if is_function(m)
			and is_constructor(m)
			and #m==0
			and m.xarg.access=='public' then
			return true
		end
	end
	return false
end
local class_is_default_constructible = entities.class_is_default_constructible

entities.default_constructor = function(t)
	if t.xarg.type_name then
		if t.xarg.type_name:match'%b[]$' then
			return 'NULL'
		elseif t.xarg.type_name:match'%(%*%)' then
			return 'NULL'
		elseif t.xarg.type_name:match'%&$' then
			return nil
		elseif t.xarg.indirections then
			return 'NULL'
		else
			return 'static_cast< '..t.xarg.type_name..' >(0)'
		end
	else
		if t.label=='Class' and class_is_default_constructible(t) then
			return t.xarg.fullname..'()'
		elseif t.label=='Class' then
			return nil
		else
			return 'static_cast< '..t.xarg.type_name..' >(0)'
		end
	end
end


return entities

