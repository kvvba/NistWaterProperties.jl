module NistWaterProperties

export get_satdata
export WaterSatProps

import HTTP
import Gumbo

mutable struct WaterSatProps
    T::Real                  # temperature (K)
    P::Real                  # pressure (Pa)
    rhol::Real               # liquid density (kg/m3)
    voll::Real               # liquid specific volume (m3/kg)
    ul::Real                 # liquid specific internal energy (J/kg)
    hl::Real                 # liquid specific enthalpy (J/kg)
    sl::Real                 # liquid specific entropy (J/kg*K)
    cvl::Real                # liquid specific heat, constant volume (J/kg*K)
    cpl::Real                # liquid specific heat, constant pressure (J/kg*K)
    cl::Real                 # liquid speed of sound (m/s)
    mujtl::Real              # liquid Joule-Thomson coefficient (K/Pa)
    mul::Real                # liquid dynamic viscosity (Pa*s)
    lambdal::Real            # liquid thermal conductivity (W/m*K)
    sigma::Real              # surface tension (N/m)
    rhov::Real               # vapour density (kg/m3)
    volv::Real               # vapour specific volume (m3/kg)
    uv::Real                 # vapour specific internal energy (J/kg)
    hv::Real                 # vapour specific enthalpy (J/kg)
    sv::Real                 # vapour specific entropy (J/kg*K)
    cvv::Real                # vapour specific heat, constant volume (J/kg*K)
    cpv::Real                # vapour specific heat, constant pressure (J/kg*K)
    cv::Real                 # vapour speed of sound (m/s)
    mujtv::Real              # vapour Joule-Thomson coefficient (K/Pa)
    muv::Real                # vapour dynamic viscosity (Pa*s)
    lambdav::Real            # vapour thermal conductivity (W/m*K)
end

function make_sat_si(data::WaterSatProps)
    data.P = data.P * 1e6
    (data.ul, data.uv) = (data.ul * 1e3, data.uv * 1e3)
    (data.hl, data.hv) = (data.hl * 1e3, data.hv * 1e3)
    (data.sl, data.sv) = (data.sl * 1e3, data.sv * 1e3)
    (data.cpl, data.cpv) = (data.cpl * 1e3, data.cpv * 1e3)
    (data.cvl, data.cvv) = (data.cvl * 1e3, data.cvv * 1e3)
    (data.mujtl, data.mujtv) = (data.mujtl * 1e-6, data.mujtv * 1e-6)
    return data
end

function get_satdata(pspec::Bool, value::Real)
    """
    get_satdata(pspec::Bool, value::Real)

    Returns a struct containing saturated water properties from the NIST webbook, specified by pressure for pspec=true and temperature for pspec=false
    """
    return make_sat_si(fetch_satdata(pspec, value))
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
    data = parse.(Float64, split(rows[2], "\t"))

    return WaterSatProps(data...)
end

end # module NistWaterProperties
