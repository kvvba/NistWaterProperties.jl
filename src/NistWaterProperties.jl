module NistWaterProperties

export get_satdata
export Fluid
export Properties

import HTTP
import Gumbo

mutable struct Fluid
    rho::Real               # density (kg/m3)
    vol::Real               # specific volume (m3/kg)
    u::Real                 # specific internal energy (J/kg)
    h::Real                 # specific enthalpy (J/kg)
    s::Real                 # specific entropy (J/kg*K)
    cv::Real                # specific heat, constant volume (J/kg*K)
    cp::Real                # specific heat, constant pressure (J/kg*K)
    c::Real                 # speed of sound (m/s)
    mujt::Real              # Joule-Thomson coefficient (K/Pa)
    mu::Real                # dynamic viscosity (Pa*s)
    lambda::Real            # thermal conductivity (W/m*K)
    phase::String           # phase
end

mutable struct Properties
    T::Real                  # temperature (K)
    P::Real                  # pressure (Pa)
    sigma::Real              # surface tension (N/m)
    phases::Dict{String, Fluid}    # dict of phases
end

function make_fluid_si(data::Fluid)
    data.u = data.u * 1e3
    data.h = data.h * 1e3
    data.s= data.s * 1e3
    data.cp = data.cp * 1e3
    data.cv = data.cv * 1e3
    data.mujt = data.mujt * 1e-6
    return data
end

function make_properties_si(data::Properties)
    data.P = data.P * 1e6
    for i in eachindex(data.phases)
        data.phases[i] = make_fluid_si(data.phases[i])
    end
    return data
end

function get_satdata(pspec::Bool, value::Real)
    """
    get_satdata(pspec::Bool, value::Real)

    Returns a struct containing saturated water properties from the NIST webbook, specified by pressure for pspec=true and temperature for pspec=false.
    Pressure is specified in MPa, temperature is specified in Kelvin.
    """
    return make_properties_si(fetch_satdata(pspec, value))
end

function fetch_satdata(pspec::Bool, value::Real)
    p_or_T = pspec ? "P" : "T"
    url = "https://webbook.nist.gov/cgi/fluid.cgi?Action=Data&Wide=on&ID=C7732185&Type=SatT&Digits=5&$(p_or_T)Low=$(value)&$(p_or_T)High=$(value)&$(p_or_T)Inc=0&RefState=DEF&TUnit=K&PUnit=MPa&DUnit=kg%2Fm3&HUnit=kJ%2Fkg&WUnit=m%2Fs&VisUnit=Pa*s&STUnit=N%2Fm"
    headers = ["User-Agent" => "Mozilla/5.0 (X11; Linux x86_64; rv:58.0) Gecko/20100101 Firefox/58.0"]

    response = HTTP.get(url, headers)

    if response.status == 200
        html_content = String(String(response.body))
        parsed = Gumbo.parsehtml(html_content)
    else
        println("Error: ", response.status)
    end

    text = ((parsed.root[2])[1]).text
    rows = split(text, "\n")
    # heading = split(rows[1], "\t")
    data = parse.(Float64, split(rows[2], "\t"))

    liquid = Fluid(data[3:13]..., "liquid")
    vapor = Fluid(data[15:25]..., "vapor")
    
    water = Properties(data[1], data[2], data[14], Dict("liquid" => liquid, "vapor" => vapor))

    return water
end

end # module NistWaterProperties
